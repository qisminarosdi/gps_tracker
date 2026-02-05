import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model representing a custom marker placed by the user
class CustomMarker {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String title;

  const CustomMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.title = 'Checkpoint',
  });

  /// Convert to Google Maps Marker
  Marker toMarker() {
    return Marker(
      markerId: MarkerId(id),
      position: LatLng(latitude, longitude),
      infoWindow: InfoWindow(
        title: title,
        snippet: _formatTimestamp(),
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
    );
  }

  String _formatTimestamp() {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
    };
  }

  /// Create from JSON
  factory CustomMarker.fromJson(Map<String, dynamic> json) {
    return CustomMarker(
      id: json['id'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      title: json['title'] as String? ?? 'Checkpoint',
    );
  }

  @override
  String toString() => 'CustomMarker(id: $id, lat: $latitude, lng: $longitude)';
}
