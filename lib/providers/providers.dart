import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/tracking_controller.dart';
import '../controllers/feed_controller.dart';
import '../models/tracking_state.dart';
import '../models/walk_session.dart';
import '../services/location_service.dart';
import '../services/screenshot_service.dart';
import '../services/storage_service.dart';
import '../services/screen_recorder_service.dart';
import '../services/session_storage_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final screenshotServiceProvider = Provider<ScreenshotService>((ref) {
  return ScreenshotService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final sessionStorageServiceProvider = Provider<SessionStorageService>((ref) {
  return SessionStorageService();
});

final screenRecorderServiceProvider = Provider<ScreenRecorderService>((ref) {
  return ScreenRecorderService();
});

final trackingControllerProvider =
    StateNotifierProvider<TrackingController, TrackingState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  final screenshotService = ref.watch(screenshotServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  final screenRecorderService = ref.watch(screenRecorderServiceProvider);
  final sessionStorageService = ref.watch(sessionStorageServiceProvider);

  return TrackingController(
    locationService: locationService,
    screenshotService: screenshotService,
    storageService: storageService,
    screenRecorderService: screenRecorderService,
    sessionStorageService: sessionStorageService,
  );
});

final walkSessionsProvider = FutureProvider<List<WalkSession>>((ref) async {
  ref.watch(sessionsRefreshProvider);
  
  final service = ref.watch(sessionStorageServiceProvider);
  return await service.getAllSessions();
});

final sessionsRefreshProvider = StateProvider<int>((ref) => 0);

// Feed controller provider
final feedControllerProvider = ChangeNotifierProvider<FeedController>((ref) {
  return FeedController();
});