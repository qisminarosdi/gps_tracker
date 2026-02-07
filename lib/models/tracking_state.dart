import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'custom_marker.dart';
import 'path_point.dart';

// Current state of GPS tracking.
class TrackingState {
  final bool isRecording;
  final bool isPaused;
  final List<PathPoint> pathPoints;
  final List<CustomMarker> markers;
  final LatLng? currentPosition;
  final String? errorMessage;
  final String? warningMessage;
  final bool isProcessing;
  final double? lastGpsAccuracy;
  final double? currentSpeed;
  final DateTime? recordingStartTime;
  final bool locationServicesDisabled;
  final bool permissionDenied;
  final bool hasGpsError;
  final bool hasRecoveredSession;
  final bool isScreenRecording;

  const TrackingState({
    this.isRecording = false,
    this.isPaused = false,
    this.pathPoints = const [],
    this.markers = const [],
    this.currentPosition,
    this.errorMessage,
    this.warningMessage,
    this.isProcessing = false,
    this.lastGpsAccuracy,
    this.currentSpeed,
    this.recordingStartTime,
    this.locationServicesDisabled = false,
    this.permissionDenied = false,
    this.hasGpsError = false,
    this.hasRecoveredSession = false,
    this.isScreenRecording = false,
  });

  TrackingState copyWith({
    bool? isRecording,
    bool? isPaused,
    List<PathPoint>? pathPoints,
    List<CustomMarker>? markers,
    LatLng? currentPosition,
    String? errorMessage,
    String? warningMessage,
    bool? isProcessing,
    double? lastGpsAccuracy,
    double? currentSpeed,
    DateTime? recordingStartTime,
    bool? locationServicesDisabled,
    bool? permissionDenied,
    bool? hasGpsError,
    bool? hasRecoveredSession,
    bool? isScreenRecording,
    bool clearError = false,
    bool clearWarning = false,
  }) {
    return TrackingState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      pathPoints: pathPoints ?? this.pathPoints,
      markers: markers ?? this.markers,
      currentPosition: currentPosition ?? this.currentPosition,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      warningMessage: clearWarning ? null : (warningMessage ?? this.warningMessage),
      isProcessing: isProcessing ?? this.isProcessing,
      lastGpsAccuracy: lastGpsAccuracy ?? this.lastGpsAccuracy,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      recordingStartTime: recordingStartTime ?? this.recordingStartTime,
      locationServicesDisabled: locationServicesDisabled ?? this.locationServicesDisabled,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      hasGpsError: hasGpsError ?? this.hasGpsError,
      hasRecoveredSession: hasRecoveredSession ?? this.hasRecoveredSession,
      isScreenRecording: isScreenRecording ?? this.isScreenRecording,
    );
  }

  Set<Polyline> get polylines {
    if (pathPoints.isEmpty) return {};

    return {
      Polyline(
        polylineId: const PolylineId('tracking_path'),
        points: pathPoints.map((p) => p.toLatLng()).toList(),
        color: const Color(0xFF705196),
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Set<Marker> get mapMarkers {
    return markers.map((m) => m.toMarker()).toSet();
  }

  bool get hasData => pathPoints.isNotEmpty || markers.isNotEmpty;

  double get totalDistance {
    if (pathPoints.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      final p1 = pathPoints[i].toLatLng();
      final p2 = pathPoints[i + 1].toLatLng();
      total += _calculateDistance(p1, p2);
    }
    return total;
  }

  Duration? get recordingDuration {
    if (recordingStartTime == null) return null;
    return DateTime.now().difference(recordingStartTime!);
  }

  GpsAccuracyStatus get accuracyStatus {
    if (lastGpsAccuracy == null) return GpsAccuracyStatus.unknown;
    if (lastGpsAccuracy! < 10) return GpsAccuracyStatus.excellent;
    if (lastGpsAccuracy! < 20) return GpsAccuracyStatus.good;
    if (lastGpsAccuracy! < 50) return GpsAccuracyStatus.fair;
    return GpsAccuracyStatus.poor;
  }

  bool get canAddMarker => isRecording && !isPaused && pathPoints.isNotEmpty;

  bool get needsPermissionSetup => 
      locationServicesDisabled || permissionDenied;

  double _calculateDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000;
    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLon = _toRadians(p2.longitude - p1.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(p1.latitude)) *
            math.cos(_toRadians(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  Map<String, dynamic> toJson() {
    return {
      'pathPoints': pathPoints.map((p) => p.toJson()).toList(),
      'markers': markers.map((m) => m.toJson()).toList(),
      'recordingStartTime': recordingStartTime?.toIso8601String(),
      'currentPosition': currentPosition != null
          ? {
              'latitude': currentPosition!.latitude,
              'longitude': currentPosition!.longitude,
            }
          : null,
    };
  }

  factory TrackingState.fromJson(Map<String, dynamic> json) {
    return TrackingState(
      pathPoints: (json['pathPoints'] as List<dynamic>?)
              ?.map((p) => PathPoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      markers: (json['markers'] as List<dynamic>?)
              ?.map((m) => CustomMarker.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      recordingStartTime: json['recordingStartTime'] != null
          ? DateTime.parse(json['recordingStartTime'] as String)
          : null,
      currentPosition: json['currentPosition'] != null
          ? LatLng(
              json['currentPosition']['latitude'] as double,
              json['currentPosition']['longitude'] as double,
            )
          : null,
    );
  }

  @override
  String toString() {
    return 'TrackingState(isRecording: $isRecording, '
        'isPaused: $isPaused, '
        'points: ${pathPoints.length}, markers: ${markers.length}, '
        'accuracy: ${lastGpsAccuracy?.toStringAsFixed(1)}m, '
        'speed: ${currentSpeed?.toStringAsFixed(1)}m/s, '
        'screenRecording: $isScreenRecording)';
  }
}

enum GpsAccuracyStatus {
  excellent,
  good,
  fair,
  poor,
  unknown,
}