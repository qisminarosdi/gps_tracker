import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/providers.dart';
import '../widgets/control_buttons.dart';
import '../widgets/info_overlay.dart';

/// Main tracking screen with map and controls
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;
  final GlobalKey _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Initialize tracking controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Map
            _buildMap(state),

            // Info overlay
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: InfoOverlay(state: state),
            ),

            // Control buttons
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: ControlButtons(
                state: state,
                mapKey: _mapKey,
                onStartRecording: _handleStartRecording,
                onStopRecording: _handleStopRecording,
                onAddMarker: _handleAddMarker,
              ),
            ),

            // Error snackbar
            if (state.errorMessage != null) _buildErrorBar(state.errorMessage!),

            // Processing indicator
            if (state.isProcessing) _buildProcessingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(state) {
    return RepaintBoundary(
      key: _mapKey,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: state.currentPosition ??
                const LatLng(37.7749, -122.4194), // Default: San Francisco
            zoom: 15,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          polylines: state.polylines,
          markers: state.mapMarkers,
          onMapCreated: (controller) {
            _mapController = controller;
            if (state.currentPosition != null) {
              _animateToPosition(state.currentPosition!);
            }
          },
          style: _mapStyle,
        ),
      ),
    );
  }

  Widget _buildErrorBar(String message) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ref.read(trackingControllerProvider.notifier).clearError();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7FFF)),
        ),
      ),
    );
  }

  void _animateToPosition(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );
  }

  void _handleStartRecording() async {
    await ref.read(trackingControllerProvider.notifier).startRecording();
  }

  void _handleStopRecording() async {
    final path = await ref
        .read(trackingControllerProvider.notifier)
        .stopRecording(mapKey: _mapKey);

    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screenshot saved: $path'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _handleAddMarker() {
    ref.read(trackingControllerProvider.notifier).addMarker();
  }

  // Minimalist map style
  static const String _mapStyle = '''
  [
    {
      "featureType": "all",
      "elementType": "geometry",
      "stylers": [{"color": "#f5f5f5"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#c9e7ff"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [{"visibility": "off"}]
    }
  ]
  ''';
}
