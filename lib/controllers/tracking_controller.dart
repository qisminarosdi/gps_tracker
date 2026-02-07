import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/tracking_state.dart';
import '../models/path_point.dart';
import '../models/custom_marker.dart';
import '../models/walk_session.dart';
import '../services/location_service.dart';
import '../services/screenshot_service.dart';
import '../services/storage_service.dart';
import '../services/screen_recorder_service.dart';
import '../services/session_storage_service.dart';

// Controller for managing GPS tracking state and operations.
class TrackingController extends StateNotifier<TrackingState> {
  final LocationService _locationService;
  final ScreenshotService _screenshotService;
  final StorageService _storageService;
  final ScreenRecorderService _screenRecorderService;
  final SessionStorageService _sessionStorageService;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _autoSaveTimer;
  Timer? _errorClearTimer;

  static const int _maxPathPoints = 10000;
  static const double _maxAccuracyMeters = 50.0;
  static const Duration _autoSaveInterval = Duration(minutes: 1);

  TrackingController({
    required LocationService locationService,
    required ScreenshotService screenshotService,
    required StorageService storageService,
    required ScreenRecorderService screenRecorderService,
    required SessionStorageService sessionStorageService,
  })  : _locationService = locationService,
        _screenshotService = screenshotService,
        _storageService = storageService,
        _screenRecorderService = screenRecorderService,
        _sessionStorageService = sessionStorageService,
        super(const TrackingState());

  // Initialize controller and request necessary permissions.
  Future<void> initialize() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          errorMessage: 'Location services disabled',
          locationServicesDisabled: true,
        );
        return;
      }

      final hasPermission = await _locationService.requestPermissions();
      if (!hasPermission) {
        state = state.copyWith(
          errorMessage: 'Location permission denied',
          permissionDenied: true,
        );
        return;
      }

      final currentPosData = await _locationService.getCurrentPosition();
      final currentPos = LatLng(currentPosData.latitude, currentPosData.longitude);
      
      // Try to restore previous session
      final recoveredState = await _storageService.recoverSession();
      if (recoveredState != null) {
        state = recoveredState.copyWith(
          currentPosition: currentPos,
          hasRecoveredSession: true,
        );
      } else {
        state = state.copyWith(currentPosition: currentPos);
      }

      final batteryOptimized = await _locationService.isBatteryOptimizationDisabled();
      if (!batteryOptimized) {
        state = state.copyWith(
          warningMessage: 'Battery optimization may affect tracking accuracy',
        );
      }
    } catch (e) {
      _setError('Initialization failed: $e');
    }
  }

  // Start GPS recording and screen recording.
  Future<void> startRecording() async {
    if (state.isRecording) return;

    try {
      // Clear previous session data before starting new recording
      state = const TrackingState();
      await _storageService.clearSession();

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Please enable location services');
        state = state.copyWith(locationServicesDisabled: true);
        return;
      }

      final hasPermission = await _locationService.requestPermissions();
      if (!hasPermission) {
        _setError('Location permission required');
        state = state.copyWith(permissionDenied: true);
        return;
      }

      final initialPosition = await _locationService.getCurrentPosition();
      final initialPoint = PathPoint.fromPosition(initialPosition);

      state = state.copyWith(
        isRecording: true,
        isPaused: false,
        pathPoints: [initialPoint],
        currentPosition: LatLng(initialPosition.latitude, initialPosition.longitude),
        recordingStartTime: DateTime.now(),
        clearError: true,
        locationServicesDisabled: false,
        permissionDenied: false,
      );

      _positionSubscription = _locationService.getPositionStreamFull().listen(
        _onPositionUpdate,
        onError: _onPositionError,
      );

      _startAutoSave();

      try {
        await _screenRecorderService.startRecording();
        state = state.copyWith(isScreenRecording: true);
      } catch (e) {
        // Ignore screen recording errors, continue with GPS tracking
      }
    } catch (e) {
      _setError('Failed to start recording: $e');
      state = state.copyWith(isRecording: false);
    }
  }

  // Pause the current recording session.
  void pauseRecording() {
    if (!state.isRecording || state.isPaused) return;
    
    _positionSubscription?.cancel();
    _positionSubscription = null;
    
    state = state.copyWith(isPaused: true);
  }

  // Resume a paused recording session.
  Future<void> resumeRecording() async {
    if (!state.isPaused) return;
    
    try {
      _positionSubscription = _locationService.getPositionStreamFull().listen(
        _onPositionUpdate,
        onError: _onPositionError,
      );
      
      state = state.copyWith(isPaused: false);
    } catch (e) {
      _setError('Failed to resume recording: $e');
    }
  }

  // Handle position updates with accuracy filtering.
  void _onPositionUpdate(Position position) {
    if (!state.isRecording || state.isPaused) return;

    if (position.accuracy > _maxAccuracyMeters) {
      state = state.copyWith(
        warningMessage: 'Low GPS accuracy (${position.accuracy.toInt()}m)',
        lastGpsAccuracy: position.accuracy,
      );
      return;
    }

    final newLatLng = LatLng(position.latitude, position.longitude);
    final lastPoint = state.pathPoints.isNotEmpty
        ? state.pathPoints.last.toLatLng()
        : null;

    if (_locationService.isValidPoint(
      newLatLng,
      lastPoint,
      position.speed,
    )) {
      final newPoint = PathPoint.fromPosition(position);
      var updatedPoints = [...state.pathPoints, newPoint];

      // Limit stored points to prevent memory issues
      if (updatedPoints.length > _maxPathPoints) {
        updatedPoints = updatedPoints.sublist(
          updatedPoints.length - _maxPathPoints,
        );
      }

      state = state.copyWith(
        pathPoints: updatedPoints,
        currentPosition: newLatLng,
        lastGpsAccuracy: position.accuracy,
        currentSpeed: position.speed,
        clearWarning: true,
      );
    }
  }

  // Handle position stream errors without stopping recording.
  void _onPositionError(dynamic error) {
    if (error is TimeoutException) {
      _setError('GPS signal lost - check your location');
    } else {
      _setError('GPS error: $error');
    }
    
    state = state.copyWith(hasGpsError: true);
  }

  // Stop recording and save screenshot, video, and WalkSession.
  Future<String?> stopRecording({GlobalKey? mapKey}) async {
    if (!state.isRecording && !state.isPaused) return null;

    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      _autoSaveTimer?.cancel();
      _autoSaveTimer = null;

      // Save current state before processing
      final recordingDuration = state.recordingDuration;
      final totalDistance = state.totalDistance;
      final pathPoints = state.pathPoints;
      final isScreenRecording = state.isScreenRecording;

      state = state.copyWith(
        isRecording: false,
        isPaused: false,
        isProcessing: true,
      );

      await _storageService.saveSession(state);

      String? screenshotPath;
      String? videoPath;

      // Stop and save screen recording
      if (isScreenRecording) {
        try {
          videoPath = await _screenRecorderService.stopRecording();
        } catch (e) {
          // Ignore video save errors
        }
      }

      // Capture screenshot
      if (mapKey != null && pathPoints.isNotEmpty) {
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          
          screenshotPath = await _screenshotService.captureAndSaveScreenshot(
            mapKey,
          );
        } catch (e) {
          // Ignore screenshot errors
        }
      }

      // Save WalkSession
      if (pathPoints.isNotEmpty) {
        final session = WalkSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          dateTime: DateTime.now(),
          duration: recordingDuration ?? Duration.zero,
          distanceMeters: totalDistance,
          recordingPath: videoPath,
          screenshotPath: screenshotPath,
          pathPoints: pathPoints,
        );
        
        await _sessionStorageService.saveSession(session);
      }

      // Clear all data and reset to fresh state
      await _storageService.clearRecoveredSession();
      state = const TrackingState();
      
      return screenshotPath;
    } catch (e) {
      _setError('Failed to stop recording: $e');
      state = state.copyWith(
        isProcessing: false,
        isRecording: false,
        isPaused: false,
        isScreenRecording: false,
      );
      return null;
    }
  }

  // Add a custom marker at current position.
  void addMarker({String? customTitle}) {
    if (state.pathPoints.isEmpty) {
      _setError('No position available. Start recording first.');
      return;
    }

    final currentPoint = state.pathPoints.last;
    final marker = CustomMarker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: currentPoint.latitude,
      longitude: currentPoint.longitude,
      timestamp: DateTime.now(),
      title: customTitle ?? 'Checkpoint ${state.markers.length + 1}',
    );

    state = state.copyWith(
      markers: [...state.markers, marker],
      clearError: true,
    );
  }

  // Recover data from a previous session.
  Future<void> recoverSession() async {
    try {
      final recoveredState = await _storageService.recoverSession();
      if (recoveredState != null) {
        state = recoveredState.copyWith(
          isRecording: false,
          isPaused: false,
          hasRecoveredSession: true,
        );
      }
    } catch (e) {
      _setError('Failed to recover session: $e');
    }
  }

  // Clear recovered session data.
  Future<void> clearRecoveredSession() async {
    await _storageService.clearRecoveredSession();
    state = state.copyWith(hasRecoveredSession: false);
  }

  // Open device location settings.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Open app settings for permissions.
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Clear all tracking data and reset state.
  void clearData() {
    _positionSubscription?.cancel();
    _autoSaveTimer?.cancel();
    _errorClearTimer?.cancel();
    _storageService.clearSession();
    state = const TrackingState();
  }

  void clearError() {
    _errorClearTimer?.cancel();
    state = state.copyWith(clearError: true);
  }

  void clearWarning() {
    state = state.copyWith(clearWarning: true);
  }

  void _setError(String message) {
    state = state.copyWith(errorMessage: message);
    
    _errorClearTimer?.cancel();
    _errorClearTimer = Timer(const Duration(seconds: 5), () {
      if (state.errorMessage == message) {
        clearError();
      }
    });
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) async {
      if (state.isRecording && !state.isPaused) {
        await _storageService.saveSession(state);
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _autoSaveTimer?.cancel();
    _errorClearTimer?.cancel();
    _screenRecorderService.dispose();
    super.dispose();
  }
}