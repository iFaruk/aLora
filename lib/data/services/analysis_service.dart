import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:fftea/fftea.dart';
import '../models/spectrum_summary.dart';

class AnalysisService {
  /// Analyzes the given image file to extract spectral data.
  ///
  /// This operation is computationally expensive and should ideally be run
  /// in a separate isolate in a production Flutter app using [compute].
  Future<SpectrumSummary> analyzeImage(File imageFile) async {
    // 1. Load image
    final bytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    // 2. Preprocessing
    // Convert to Grayscale
    img.Image grayImage = img.grayscale(originalImage);

    // Apply Strong Gaussian Blur (radius 5-10)
    // Using radius 8 as a sweet spot
    img.Image blurredImage = img.gaussianBlur(grayImage, radius: 8);

    // Determine if we need to invert.
    // We assume "ink" is the object of interest.
    // If the corners are dark, it's likely light ink on dark background.
    // If the corners are light, it's likely dark ink on light background.
    // We want "Ink" to be "Black" (low value) for the logic "If pixels are black...".

    // Check average luminance of corners to guess background color.
    int w = blurredImage.width;
    int h = blurredImage.height;

    // Sample corners
    final corners = [
      blurredImage.getPixel(0, 0),
      blurredImage.getPixel(w - 1, 0),
      blurredImage.getPixel(0, h - 1),
      blurredImage.getPixel(w - 1, h - 1),
    ];

    double avgCornerLuma = 0;
    for (var p in corners) {
      avgCornerLuma += p.luminanceNormalized;
    }
    avgCornerLuma /= 4.0;

    bool isDarkBackground = avgCornerLuma < 0.5;

    // If dark background, invert so background becomes light and ink becomes dark.
    if (isDarkBackground) {
      blurredImage = img.invert(blurredImage);
    }

    // Apply Threshold to separate main ink body from background noise.
    // Since we ensured background is light (high value), Ink is dark (low value).
    // Threshold: Pixels below value are Ink.
    const int thresholdValue = 128;

    int inkPixelCount = 0;
    int totalPixels = w * h;

    // 3. Centroid Calculation
    double sumX = 0;
    double sumY = 0;

    // Iterate pixels
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = blurredImage.getPixel(x, y);
        final luma = pixel.luminance;

        // If pixel is "black" (Ink) -> luma < threshold
        if (luma < thresholdValue) {
          inkPixelCount++;
          sumX += x;
          sumY += y;
        }
      }
    }

    double density = inkPixelCount / totalPixels;

    double centerX = w / 2;
    double centerY = h / 2;

    if (inkPixelCount > 0) {
      centerX = sumX / inkPixelCount;
      centerY = sumY / inkPixelCount;
    }

    // 4. Density Raycasting
    // Cast 512 rays from Centroid (Power of 2 for FFT).
    List<double> rayDistances = [];

    const int numRays = 512;
    // Max radius covers the whole image from centroid
    double maxRadius = math.sqrt(w * w + h * h);

    for (int i = 0; i < numRays; i++) {
      // Calculate angle for 512 rays distributed over 360 degrees (2*PI)
      double angleRad = i * (2 * math.pi / numRays);
      double dirX = math.cos(angleRad);
      double dirY = math.sin(angleRad);

      double weightedSumDist = 0;
      double totalWeight = 0;

      // Iterate outwards
      for (double r = 0; r < maxRadius; r += 1.0) {
        int px = (centerX + dirX * r).round();
        int py = (centerY + dirY * r).round();

        // Check bounds
        if (px < 0 || px >= w || py < 0 || py >= h) {
          break; // Hit edge of image
        }

        final pixel = blurredImage.getPixel(px, py);
        final luma = pixel.luminance;

        // If pixel is Ink (black)
        if (luma < thresholdValue) {
          // "Center of Gravity of the ink along that ray"
          // We treat the existence of ink as weight (1).
          weightedSumDist += r;
          totalWeight += 1;
        }
      }

      if (totalWeight > 0) {
        rayDistances.add(weightedSumDist / totalWeight);
      } else {
        // No ink found in this direction
        rayDistances.add(0.0);
      }
    }

    // 5. Spectral Extraction
    // Convert distance values into frequency spectrum using FFT.

    final fft = FFT(numRays);
    final spectrum = fft.realFft(rayDistances);

    // Identify Base Shape (Dominant low frequencies)
    // Frequency bins:
    // Index 0: DC component (average radius)
    // Index 1: Fundamental frequency (1 cycle per 360 deg / full rotation)
    // ...

    List<double> dominantFrequencies = [];
    // Let's take bins 1 to 5 (ignoring DC)
    for (int i = 1; i <= 5; i++) {
        final c = spectrum[i];
        double magnitude = math.sqrt(c.x * c.x + c.y * c.y);
        dominantFrequencies.add(magnitude);
    }

    // Roughness (Texture): High-frequency noise level.
    // Sum magnitudes from index 20 to Nyquist limit (numRays / 2).
    double chaosLevel = 0;
    int nyquist = numRays ~/ 2;

    for (int i = 20; i < nyquist; i++) {
        final c = spectrum[i];
        chaosLevel += math.sqrt(c.x * c.x + c.y * c.y);
    }

    // Optional Normalization
    double averageRadius = math.sqrt(spectrum[0].x * spectrum[0].x + spectrum[0].y * spectrum[0].y);
    if (averageRadius > 0) {
       chaosLevel /= averageRadius;
       for(int i=0; i<dominantFrequencies.length; i++) {
           dominantFrequencies[i] /= averageRadius;
       }
    }

    return SpectrumSummary(
      dominantFrequencies: dominantFrequencies,
      chaosLevel: chaosLevel,
      density: density,
    );
  }
}
