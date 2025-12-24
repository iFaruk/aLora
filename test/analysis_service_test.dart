import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:orbita/data/services/analysis_service.dart';
import 'package:orbita/data/models/spectrum_summary.dart';

void main() {
  group('AnalysisService', () {
    late AnalysisService service;
    late File tempFile;

    setUp(() async {
      service = AnalysisService();

      // Create a temporary image file for testing
      // 100x100 white background, black square in middle
      final image = img.Image(width: 100, height: 100, numChannels: 3);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      img.fillRect(image, x1: 25, y1: 25, x2: 75, y2: 75, color: img.ColorRgb8(0, 0, 0));

      final tempDir = Directory.systemTemp.createTempSync('analysis_test_');
      tempFile = File('${tempDir.path}/test_image.png');
      await tempFile.writeAsBytes(img.encodePng(image));
    });

    tearDown(() {
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    });

    test('analyzeImage returns valid SpectrumSummary', () async {
      final summary = await service.analyzeImage(tempFile);

      expect(summary, isNotNull);
      expect(summary.dominantFrequencies, isNotEmpty);
      expect(summary.chaosLevel, isNonNegative);
      expect(summary.density, isPositive); // Should have some density

      // Density check: 50x50 square in 100x100 image = 2500 / 10000 = 0.25
      // With blur, it might vary slightly.
      expect(summary.density, closeTo(0.25, 0.05));
    });
  });
}
