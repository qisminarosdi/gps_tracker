import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service responsible for location tracking and GPS operations
class LocationService {
  static const double _noiseFilterDistanceMeters = 50.0;
  static const int _minDistanceFilterMeters = 5;

  /// Request location permissions
  Future<bool> requestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied. '
        'Please enable them in settings.',
      );
    }

    return true;
  }

  /// Get current position
  Future<LatLng> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Failed to get current position: $e');
    }
  }

  /// Start listening to position updates
  Stream<LatLng> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: _minDistanceFilterMeters,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) => LatLng(position.latitude, position.longitude));
  }

  /// Validate if a new point should be added (filter GPS noise)
  bool isValidPoint(LatLng newPoint, LatLng? lastPoint) {
    // Always accept first point
    if (lastPoint == null) return true;

    // Calculate distance from last point
    final distance = Geolocator.distanceBetween(
      lastPoint.latitude,
      lastPoint.longitude,
      newPoint.latitude,
      newPoint.longitude,
    );

    // Reject points that are too far (likely GPS jumps/noise)
    return distance < _noiseFilterDistanceMeters;
  }

  /// Calculate distance between two points in meters
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  /// Calculate total distance of a path
  double calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += calculateDistance(points[i], points[i + 1]);
    }
    return totalDistance;
  }
}
