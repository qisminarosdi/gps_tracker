import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class PathPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
  final double? altitude;
  final double? accuracy;
  final double? heading;

  const PathPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.altitude,
    this.accuracy,
    this.heading,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  factory PathPoint.fromLatLng(LatLng latLng) {
    return PathPoint(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      timestamp: DateTime.now(),
    );
  }

  factory PathPoint.fromPosition(Position position) {
    return PathPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      speed: position.speed,
      altitude: position.altitude,
      accuracy: position.accuracy,
      heading: position.heading,
    );
  }

  bool get isHighAccuracy => accuracy != null && accuracy! < 20.0;

  bool get hasSpeed => speed != null && speed! > 0;

  double? get speedKmh => speed != null ? speed! * 3.6 : null;

  String get formattedSpeed {
    if (speed == null || speed! <= 0) return '0 km/h';
    return '${speedKmh!.toStringAsFixed(1)} km/h';
  }

  String get formattedAccuracy {
    if (accuracy == null) return 'Unknown';
    return '±${accuracy!.toStringAsFixed(0)}m';
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      if (speed != null) 'speed': speed,
      if (altitude != null) 'altitude': altitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (heading != null) 'heading': heading,
    };
  }

  factory PathPoint.fromJson(Map<String, dynamic> json) {
    return PathPoint(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: json['speed'] as double?,
      altitude: json['altitude'] as double?,
      accuracy: json['accuracy'] as double?,
      heading: json['heading'] as double?,
    );
  }

  PathPoint copyWith({
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? speed,
    double? altitude,
    double? accuracy,
    double? heading,
  }) {
    return PathPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      heading: heading ?? this.heading,
    );
  }

  @override
  String toString() =>
      'PathPoint(lat: ${latitude.toStringAsFixed(6)}, '
      'lng: ${longitude.toStringAsFixed(6)}, '
      'time: $timestamp'
      '${speed != null ? ', speed: ${formattedSpeed}' : ''}'
      '${accuracy != null ? ', accuracy: ${formattedAccuracy}' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      latitude.hashCode ^ longitude.hashCode ^ timestamp.hashCode;
}