import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// GPS + location tracking logic
class LocationService {
  static const double _noiseFilterDistanceMeters = 50.0;
  static const double _fastMovementThreshold = 100.0;
  static const int _minDistanceFilterMeters = 5;
  static const double _speedThresholdMps = 5.0;
  static const int _gpsTimeoutSeconds = 10;
  
  // Cache for faster initial load
  Position? _lastKnownPosition;
  DateTime? _lastPositionTime;
  static const Duration _cacheValidity = Duration(minutes: 5);

  Future<bool> requestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

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

  Future<bool> hasPermissions() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position> getCurrentPosition() async {
    try {
      if (_lastKnownPosition != null && _lastPositionTime != null) {
        final age = DateTime.now().difference(_lastPositionTime!);
        if (age < _cacheValidity) {
          _updatePositionInBackground();
          return _lastKnownPosition!;
        }
      }
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _lastKnownPosition = lastKnown;
        _lastPositionTime = DateTime.now();
        
        // Get fresh position in background
        _updatePositionInBackground();
        
        return lastKnown;
      }

      // reduced timeout 
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      _lastKnownPosition = position;
      _lastPositionTime = DateTime.now();
      
      return position;
    } catch (e) {
      if (_lastKnownPosition != null) {
        return _lastKnownPosition!;
      }
      throw Exception('Failed to get current position: $e');
    }
  }

  void _updatePositionInBackground() {
    Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: const Duration(seconds: 10),
    ).then((position) {
      _lastKnownPosition = position;
      _lastPositionTime = DateTime.now();
    }).catchError((_) {
    });
  }

  Stream<Position> getPositionStreamFull() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: _minDistanceFilterMeters,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .timeout(
          const Duration(seconds: _gpsTimeoutSeconds),
          onTimeout: (sink) {
            sink.addError(
              TimeoutException('GPS signal lost', 
                const Duration(minutes: 5)),
            );
          },
        );
  }

  Stream<LatLng> getPositionStream() {
    return getPositionStreamFull()
        .where((position) => position.accuracy < 50)
        .map((position) => LatLng(position.latitude, position.longitude));
  }

  bool isValidPoint(LatLng newPoint, LatLng? lastPoint, double? speed) {
    if (lastPoint == null) {
      return true;
    }

    final distance = Geolocator.distanceBetween(
      lastPoint.latitude,
      lastPoint.longitude,
      newPoint.latitude,
      newPoint.longitude,
    );

    final threshold = (speed != null && speed > _speedThresholdMps)
        ? _fastMovementThreshold
        : _noiseFilterDistanceMeters;

    return distance < threshold;
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  double calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += calculateDistance(points[i], points[i + 1]);
    }
    return totalDistance;
  }

  Future<bool> isBatteryOptimizationDisabled() async {
    try {
      return true;
    } catch (e) {
      return true;
    }
  }

  Future<LocationServiceStatus> checkServiceStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationServiceStatus.disabled;
    }

    final permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.denied:
        return LocationServiceStatus.permissionDenied;
      case LocationPermission.deniedForever:
        return LocationServiceStatus.permissionDeniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationServiceStatus.ready;
      default:
        return LocationServiceStatus.unknown;
    }
  }

  double calculateAverageSpeed(List<Position> positions) {
    if (positions.length < 2) return 0.0;

    double totalSpeed = 0.0;
    int validSpeeds = 0;

    for (final position in positions) {
      if (position.speed > 0) {
        totalSpeed += position.speed;
        validSpeeds++;
      }
    }

    return validSpeeds > 0 ? totalSpeed / validSpeeds : 0.0;
  }

  String formatSpeed(double speedMps) {
    final speedKmh = speedMps * 3.6;
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }
 
  void clearCache() {
    _lastKnownPosition = null;
    _lastPositionTime = null;
  }
}

enum LocationServiceStatus {
  ready,
  disabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}