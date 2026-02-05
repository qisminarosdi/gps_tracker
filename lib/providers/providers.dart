import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/tracking_controller.dart';
import '../models/tracking_state.dart';
import '../services/location_service.dart';
import '../services/screenshot_service.dart';

/// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for ScreenshotService
final screenshotServiceProvider = Provider<ScreenshotService>((ref) {
  return ScreenshotService();
});

/// Provider for TrackingController
final trackingControllerProvider =
    StateNotifierProvider<TrackingController, TrackingState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  final screenshotService = ref.watch(screenshotServiceProvider);

  return TrackingController(
    locationService: locationService,
    screenshotService: screenshotService,
  );
});
