import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Handles map screenshot capture and storage
class ScreenshotService {
  /// Captures widget as image and saves to device storage
  Future<String> captureAndSaveScreenshot(GlobalKey key) async {
    try {
      // Render widget to image with 3x quality
      final RenderRepaintBoundary boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      
      // Convert to PNG bytes
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      // Save to app documents with timestamp filename
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'path_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return filePath;
    } catch (e) {
      throw Exception('Failed to capture screenshot: $e');
    }
  }

  /// Returns all saved screenshots sorted by newest first
  Future<List<String>> getSavedScreenshots() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('path_') && f.path.endsWith('.png'))
          .map((f) => f.path)
          .toList();

      files.sort((a, b) => b.compareTo(a));
      return files;
    } catch (e) {
      throw Exception('Failed to get saved screenshots: $e');
    }
  }

  /// Deletes screenshot file if it exists
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