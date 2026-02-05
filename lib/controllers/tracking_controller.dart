import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/tracking_state.dart';
import '../models/path_point.dart';
import '../models/custom_marker.dart';
import '../services/location_service.dart';
import '../services/screenshot_service.dart';

/// Controller for managing GPS tracking state and operations
class TrackingController extends StateNotifier<TrackingState> {
  final LocationService _locationService;
  final ScreenshotService _screenshotService;
  StreamSubscription<LatLng>? _positionSubscription;

  TrackingController({
    required LocationService locationService,
    required ScreenshotService screenshotService,
  })  : _locationService = locationService,
        _screenshotService = screenshotService,
        super(const TrackingState());

  /// Initialize and request permissions
  Future<void> initialize() async {
    try {
      await _locationService.requestPermissions();
      final currentPos = await _locationService.getCurrentPosition();
      state = state.copyWith(currentPosition: currentPos);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Start recording GPS path
  Future<void> startRecording() async {
    if (state.isRecording) return;

    try {
      // Request permissions if not already granted
      await _locationService.requestPermissions();

      // Get initial position
      final initialPos = await _locationService.getCurrentPosition();
      final initialPoint = PathPoint.fromLatLng(initialPos);

      state = state.copyWith(
        isRecording: true,
        pathPoints: [initialPoint],
        currentPosition: initialPos,
        clearError: true,
      );

      // Start listening to position stream
      _positionSubscription = _locationService.getPositionStream().listen(
        (position) => _onPositionUpdate(position),
        onError: (error) => _onPositionError(error),
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start recording: $e',
        isRecording: false,
      );
    }
  }

  /// Handle position updates
  void _onPositionUpdate(LatLng position) {
    if (!state.isRecording) return;

    final lastPoint = state.pathPoints.isNotEmpty
        ? state.pathPoints.last.toLatLng()
        : null;

    // Validate point to filter GPS noise
    if (_locationService.isValidPoint(position, lastPoint)) {
      final newPoint = PathPoint.fromLatLng(position);
      state = state.copyWith(
        pathPoints: [...state.pathPoints, newPoint],
        currentPosition: position,
      );
    }
  }

  /// Handle position stream errors
  void _onPositionError(dynamic error) {
    state = state.copyWith(
      errorMessage: 'GPS error: $error',
      isRecording: false,
    );
    _positionSubscription?.cancel();
  }

  /// Stop recording and optionally save screenshot
  Future<String?> stopRecording({GlobalKey? mapKey}) async {
    if (!state.isRecording) return null;

    try {
      // Stop position stream
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      state = state.copyWith(
        isRecording: false,
        isProcessing: true,
      );

      // Capture screenshot if map key provided
      String? screenshotPath;
      if (mapKey != null && state.hasData) {
        screenshotPath = await _screenshotService.captureAndSaveScreenshot(
          mapKey,
        );
      }

      state = state.copyWith(isProcessing: false);
      return screenshotPath;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to stop recording: $e',
        isProcessing: false,
        isRecording: false,
      );
      return null;
    }
  }

  /// Add a custom marker at current position
  void addMarker() {
    if (state.pathPoints.isEmpty) {
      state = state.copyWith(
        errorMessage: 'No position available. Start recording first.',
      );
      return;
    }

    final currentPoint = state.pathPoints.last;
    final marker = CustomMarker(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: currentPoint.latitude,
      longitude: currentPoint.longitude,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      markers: [...state.markers, marker],
      clearError: true,
    );
  }

  /// Clear all tracking data
  void clearData() {
    state = const TrackingState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
