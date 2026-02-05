import 'dart:ui';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'custom_marker.dart';
import 'path_point.dart';

/// Represents the current state of GPS tracking
class TrackingState {
  final bool isRecording;
  final List<PathPoint> pathPoints;
  final List<CustomMarker> markers;
  final LatLng? currentPosition;
  final String? errorMessage;
  final bool isProcessing;

  const TrackingState({
    this.isRecording = false,
    this.pathPoints = const [],
    this.markers = const [],
    this.currentPosition,
    this.errorMessage,
    this.isProcessing = false,
  });

  /// Create a copy with modified fields
  TrackingState copyWith({
    bool? isRecording,
    List<PathPoint>? pathPoints,
    List<CustomMarker>? markers,
    LatLng? currentPosition,
    String? errorMessage,
    bool? isProcessing,
    bool clearError = false,
  }) {
    return TrackingState(
      isRecording: isRecording ?? this.isRecording,
      pathPoints: pathPoints ?? this.pathPoints,
      markers: markers ?? this.markers,
      currentPosition: currentPosition ?? this.currentPosition,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  /// Get polylines for the map
  Set<Polyline> get polylines {
    if (pathPoints.isEmpty) return {};

    return {
      Polyline(
        polylineId: const PolylineId('tracking_path'),
        points: pathPoints.map((p) => p.toLatLng()).toList(),
        color: const Color(0xFF6B7FFF), // Soft blue
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  /// Get markers for the map
  Set<Marker> get mapMarkers {
    return markers.map((m) => m.toMarker()).toSet();
  }

  /// Check if there's any tracked data
  bool get hasData => pathPoints.isNotEmpty || markers.isNotEmpty;

  @override
  String toString() {
    return 'TrackingState(isRecording: $isRecording, '
        'points: ${pathPoints.length}, markers: ${markers.length})';
  }
}
