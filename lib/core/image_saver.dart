import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/models/heptapod_spectrum.dart';
import '../ui/painters/heptapod_painter.dart';

class ImageSaver {
  static Future<void> saveHighQualityImage(
      HeptapodSpectrum spectrum,
      {double size = 2048.0}) async {

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Note: If exact reproduction is needed, the seed should be stored in the state.
    // Currently using default seed behavior.
    final painter = HeptapodPainter(spectrum: spectrum);

    // Fill background with black (Zen Theme)
    final bgPaint = Paint()..color = const Color(0xFF101010);
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), bgPaint);

    painter.paint(canvas, Size(size, size));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      final buffer = byteData.buffer.asUint8List();

      try {
        // NOTE: On Mobile, FilePicker.platform.saveFile is not supported or does not work as "Save to Gallery".
        // The requested package 'image_gallery_saver' is not available in the current environment's pubspec.yaml.
        // We use FilePicker as the best available alternative given constraints.
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Logogram',
          fileName: 'heptapod_logogram.png',
          bytes: buffer,
          type: FileType.image,
        );

        if (outputFile == null) {
           debugPrint('User canceled save.');
        } else {
           debugPrint('Saved to $outputFile');
        }
      } catch (e) {
        debugPrint('Error saving file: $e');
      }
    }
  }
}
