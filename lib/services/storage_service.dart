import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracking_state.dart';

// Saves tracking data to device storage
class StorageService {
  static const String _sessionKey = 'tracking_session';
  static const String _hasRecoveredSessionKey = 'has_recovered_session';
  
  Future<void> saveSession(TrackingState state) async {
    try {
      if (!state.hasData) return;

      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(state.toJson());
      await prefs.setString(_sessionKey, jsonString);
      await prefs.setBool(_hasRecoveredSessionKey, false);
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<TrackingState?> recoverSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final hasRecovered = prefs.getBool(_hasRecoveredSessionKey) ?? true;
      if (hasRecovered) return null;

      final jsonString = prefs.getString(_sessionKey);
      if (jsonString == null) return null;

      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final state = TrackingState.fromJson(jsonData);

      await prefs.setBool(_hasRecoveredSessionKey, true);

      return state.hasData ? state : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.setBool(_hasRecoveredSessionKey, true);
    } catch (e) {
      // Ignore clear errors
    }
  }

  Future<void> clearRecoveredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasRecoveredSessionKey, true);
    } catch (e) {
      // Ignore errors
    }
  }

  Future<bool> hasSessionToRecover() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRecovered = prefs.getBool(_hasRecoveredSessionKey) ?? true;
      final jsonString = prefs.getString(_sessionKey);
      return !hasRecovered && jsonString != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> saveCompletedTrack(
    TrackingState state,
    String? screenshotPath,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final tracksJson = prefs.getString('completed_tracks') ?? '[]';
      final tracks = json.decode(tracksJson) as List<dynamic>;

      final trackData = {
        ...state.toJson(),
        'completedAt': DateTime.now().toIso8601String(),
        'screenshotPath': screenshotPath,
        'totalDistance': state.totalDistance,
        'duration': state.recordingDuration?.inSeconds,
      };

      tracks.add(trackData);

      if (tracks.length > 50) {
        tracks.removeAt(0);
      }

      await prefs.setString('completed_tracks', json.encode(tracks));
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<List<Map<String, dynamic>>> getCompletedTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tracksJson = prefs.getString('completed_tracks') ?? '[]';
      final tracks = json.decode(tracksJson) as List<dynamic>;
      return tracks.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}