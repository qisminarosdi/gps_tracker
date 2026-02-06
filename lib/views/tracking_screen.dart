import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gps_tracker_app/models/tracking_state.dart';
import '../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../providers/saved_screenshots_provider.dart';
import '../widgets/control_buttons.dart';
import '../widgets/info_overlay.dart';
import '../widgets/gps_status_indicator.dart';
import '../widgets/permission_overlay.dart';
import '../widgets/recovery_dialog.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/walk_completed_dialog.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;
  final GlobalKey _mapKey = GlobalKey();
  bool _hasShownRecoveryDialog = false;
  bool _showingCountdown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingControllerProvider);

    if (state.hasRecoveredSession && !_hasShownRecoveryDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRecoveryDialog(state);
      });
    }

    ref.listen<TrackingState>(
      trackingControllerProvider,
      (previous, next) {
        if (next.currentPosition != null &&
            next.currentPosition != previous?.currentPosition) {
          _animateToPosition(next.currentPosition!);
        }
      },
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Walking Tracker'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildMap(state),

            if (_showingCountdown)
              CountdownOverlay(
                onComplete: () {
                  setState(() => _showingCountdown = false);
                  _startRecordingAfterCountdown();
                },
              ),

            if (state.currentPosition == null && !state.needsPermissionSetup)
              _buildLocationLoadingOverlay(),

            if (state.needsPermissionSetup)
              PermissionOverlay(
                locationServicesDisabled: state.locationServicesDisabled,
                permissionDenied: state.permissionDenied,
                onOpenLocationSettings: _handleOpenLocationSettings,
                onOpenAppSettings: _handleOpenAppSettings,
              ),

            if (state.currentPosition != null && state.isRecording)
              Positioned(
                top: 16,
                right: 16,
                child: GpsStatusIndicator(state: state),
              ),

            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: InfoOverlay(state: state),
            ),

            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: ControlButtons(
                state: state,
                mapKey: _mapKey,
                onStartRecording: _handleStartRecording,
                onPauseRecording: _handlePauseRecording,
                onResumeRecording: _handleResumeRecording,
                onEndWalk: _handleEndWalk,
                onAddMarker: _handleAddMarker,
              ),
            ),

            if (state.warningMessage != null && !state.needsPermissionSetup)
              _buildWarningBanner(state.warningMessage!),

            if (state.errorMessage != null && !state.needsPermissionSetup)
              _buildErrorBar(state.errorMessage!),

            if (state.isProcessing) _buildProcessingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(TrackingState state) {
    return RepaintBoundary(
      key: _mapKey,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: state.currentPosition ??
                const LatLng(3.0291183, 101.7105917),
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
            _applyMapStyle(controller);
            if (state.currentPosition != null) {
              _animateToPosition(state.currentPosition!);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLocationLoadingOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Opacity(
                    opacity: 0.5 + (value * 0.5),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withValues(alpha:0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        size: 40,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                );
              },
              onEnd: () {
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Getting your location...',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we locate you',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyMapStyle(GoogleMapController controller) async {
    try {
      await controller.setMapStyle(_mapStyle);
    } catch (e) {
      // Ignore map style errors
    }
  }

  Widget _buildWarningBanner(String message) {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: AppTheme.warningOrange,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.white, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ref.read(trackingControllerProvider.notifier).clearWarning();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBar(String message) {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: AppTheme.errorRed,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.white, size: 20),
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
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
            const SizedBox(height: 16),
            Text(
              'Processing...',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _animateToPosition(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 17),
    );
  }

  Future<void> _handleStartRecording() async {
    setState(() => _showingCountdown = true);
  }

  Future<void> _startRecordingAfterCountdown() async {
    await ref.read(trackingControllerProvider.notifier).startRecording();
  }

  void _handlePauseRecording() {
    ref.read(trackingControllerProvider.notifier).pauseRecording();
  }

  Future<void> _handleResumeRecording() async {
    await ref.read(trackingControllerProvider.notifier).resumeRecording();
  }

  Future<void> _handleEndWalk() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: AppTheme.dialogShape,
        title: const Text('Confirm end walk?', style: AppTheme.dialogTitle),
        content: const Text(
          'By proceeding, your walk will be marked as done.',
          style: AppTheme.dialogContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: AppTheme.textButton,
            child: const Text('Back to Walk'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: AppTheme.dangerButton,
            child: const Text('End Walk'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _stopAndShowResults();
    }
  }

  Future<void> _stopAndShowResults() async {
    final state = ref.read(trackingControllerProvider);
    final duration = state.recordingDuration ?? Duration.zero;
    final distanceKm = state.totalDistance / 1000;

    // Stop recording and save session
    final path = await ref
        .read(trackingControllerProvider.notifier)
        .stopRecording(mapKey: _mapKey);

    ref.read(sessionsRefreshProvider.notifier).state++;
    ref.read(screenshotsRefreshProvider.notifier).state++;
    ref.invalidate(walkSessionsProvider);
    ref.invalidate(savedScreenshotsProvider);

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WalkCompletedDialog(
        duration: duration,
        distanceKm: distanceKm,
        onDone: () {
          Navigator.pop(context);
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackbar(
              'Successfully saved screenshot and recording. You can view it in walking history.',
            ),
          );
        },
      ),
    );
  }

  void _handleAddMarker() {
    ref.read(trackingControllerProvider.notifier).addMarker();
  }

  void _handleOpenLocationSettings() {
    ref.read(trackingControllerProvider.notifier).openLocationSettings();
  }

  void _handleOpenAppSettings() {
    ref.read(trackingControllerProvider.notifier).openAppSettings();
  }

  void _showRecoveryDialog(TrackingState state) {
    if (!mounted) return;
    _hasShownRecoveryDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RecoveryDialog(
        pointsCount: state.pathPoints.length,
        markersCount: state.markers.length,
        distance: state.totalDistance,
        onRestore: () => Navigator.of(context).pop(),
        onDiscard: () {
          ref.read(trackingControllerProvider.notifier).clearData();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

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