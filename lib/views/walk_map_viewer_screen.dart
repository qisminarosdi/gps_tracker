import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/theme/app_theme.dart';
import '../models/walk_session.dart';
import '../models/path_point.dart';

class WalkMapViewerScreen extends StatefulWidget {
  final WalkSession session;

  const WalkMapViewerScreen({super.key, required this.session});

  @override
  State<WalkMapViewerScreen> createState() => _WalkMapViewerScreenState();
}

class _WalkMapViewerScreenState extends State<WalkMapViewerScreen> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.pathPoints.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Walk Route'),
          backgroundColor: AppTheme.white,
        ),
        body: const Center(
          child: Text(
            'No route data available',
            style: AppTheme.bodyLarge,
          ),
        ),
      );
    }

    final polyline = Polyline(
      polylineId: const PolylineId('walk_path'),
      points: widget.session.pathPoints.map((p) => p.toLatLng()).toList(),
      color: AppTheme.primaryPurple,
      width: 4,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );

    final bounds = _calculateBounds(widget.session.pathPoints);
    final startPoint = widget.session.pathPoints.first;
    final endPoint = widget.session.pathPoints.last;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('start'),
        position: startPoint.toLatLng(),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Start'),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: endPoint.toLatLng(),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'End'),
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk Route'),
        backgroundColor: AppTheme.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: bounds.center,
          zoom: 14,
        ),
        polylines: {polyline},
        markers: markers,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
        compassEnabled: true,
        onMapCreated: (controller) {
          _mapController = controller;
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              controller.animateCamera(
                CameraUpdate.newLatLngBounds(bounds.latLngBounds, 80),
              );
            }
          });
        },
      ),
    );
  }

  _MapBounds _calculateBounds(List<PathPoint> pathPoints) {
    if (pathPoints.isEmpty) {
      return _MapBounds(
        center: const LatLng(0, 0),
        latLngBounds: LatLngBounds(
          southwest: const LatLng(0, 0),
          northeast: const LatLng(0, 0),
        ),
      );
    }

    double minLat = pathPoints.first.latitude;
    double maxLat = pathPoints.first.latitude;
    double minLng = pathPoints.first.longitude;
    double maxLng = pathPoints.first.longitude;

    for (final point in pathPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    return _MapBounds(
      center: LatLng(centerLat, centerLng),
      latLngBounds: LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
    );
  }
}

class _MapBounds {
  final LatLng center;
  final LatLngBounds latLngBounds;

  _MapBounds({
    required this.center,
    required this.latLngBounds,
  });
}