import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Service responsible for capturing and saving map screenshots
class ScreenshotService {
  /// Capture screenshot from a RepaintBoundary key
  Future<String> captureAndSaveScreenshot(GlobalKey key) async {
    try {
      // Get the render object
      final RenderRepaintBoundary boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary;

      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Convert to byte data
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      // Get the directory to save
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'path_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';

      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return filePath;
    } catch (e) {
      throw Exception('Failed to capture screenshot: $e');
    }
  }

  /// Get list of saved screenshots
  Future<List<String>> getSavedScreenshots() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('path_') && f.path.endsWith('.png'))
          .map((f) => f.path)
          .toList();

      // Sort by date (newest first)
      files.sort((a, b) => b.compareTo(a));
      return files;
    } catch (e) {
      throw Exception('Failed to get saved screenshots: $e');
    }
  }

  /// Delete a screenshot file
  Future<void> deleteScreenshot(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete screenshot: $e');
    }
  }
}
