import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model representing a GPS coordinate point
class PathPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const PathPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  /// Convert to LatLng for Google Maps
  LatLng toLatLng() => LatLng(latitude, longitude);

  /// Create from LatLng
  factory PathPoint.fromLatLng(LatLng latLng) {
    return PathPoint(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      timestamp: DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory PathPoint.fromJson(Map<String, dynamic> json) {
    return PathPoint(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() =>
      'PathPoint(lat: $latitude, lng: $longitude, time: $timestamp)';
}
