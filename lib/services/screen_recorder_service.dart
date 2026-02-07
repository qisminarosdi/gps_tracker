import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';

// handle screen recording
class ScreenRecorderService {
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<void> startRecording() async {
    try {
      if (_isRecording) {
        return;
      }

      final started = await FlutterScreenRecording.startRecordScreen(
        'tracking_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (started) {
        _isRecording = true;
      } else {
        throw Exception('Failed to start recording');
      }
    } catch (e) {
      throw Exception('Failed to start screen recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        return null;
      }

      final recordingPath = await FlutterScreenRecording.stopRecordScreen;
      _isRecording = false;
      
      if (recordingPath.isNotEmpty) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final filePath = '${directory.path}/$fileName';
        
        final file = File(recordingPath);
        if (await file.exists()) {
          final savedFile = await file.copy(filePath);
          
          try {
            await file.delete();
          } catch (e) {
            // Ignore temp file deletion errors
          }
          
          return savedFile.path;
        }
      }
      
      return null;
    } catch (e) {
      _isRecording = false;
      return null;
    }
  }

  Future<List<String>> getSavedRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('recording_') && f.path.endsWith('.mp4'))
          .map((f) => f.path)
          .toList();

      files.sort((a, b) => b.compareTo(a));
      return files;
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete recording: $e');
    }
  }

  Future<void> cancelRecording() async {
    if (_isRecording) {
      try {
        await FlutterScreenRecording.stopRecordScreen;
        _isRecording = false;
      } catch (e) {
        // Ignore cancellation errors
      }
    }
  }

  void dispose() {
    _isRecording = false;
  }
}