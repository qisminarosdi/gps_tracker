import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/walk_session.dart';

class SessionStorageService {
  static const String _sessionsKey = 'walk_sessions';

  Future<void> saveSession(WalkSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getAllSessions();
      
      sessions.add(session);
      
      final jsonList = sessions.map((s) => s.toJson()).toList();
      await prefs.setString(_sessionsKey, json.encode(jsonList));
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<List<WalkSession>> getAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_sessionsKey);
      
      if (jsonString == null) return [];
      
      final jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => WalkSession.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    } catch (e) {
      return [];
    }
  }

  Future<WalkSession?> getSessionById(String id) async {
    try {
      final sessions = await getAllSessions();
      return sessions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<WalkSession?> getSessionByScreenshot(String screenshotPath) async {
    try {
      final sessions = await getAllSessions();
      return sessions.firstWhere((s) => s.screenshotPath == screenshotPath);
    } catch (e) {
      return null;
    }
  }

  Future<WalkSession?> getSessionByRecording(String recordingPath) async {
    try {
      final sessions = await getAllSessions();
      return sessions.firstWhere((s) => s.recordingPath == recordingPath);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getAllSessions();
      
      sessions.removeWhere((s) => s.id == id);
      
      final jsonList = sessions.map((s) => s.toJson()).toList();
      await prefs.setString(_sessionsKey, json.encode(jsonList));
    } catch (e) {
      // Ignore delete errors
    }
  }

  Future<void> clearAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionsKey);
    } catch (e) {
      // Ignore clear errors
    }
  }
}