import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';

// Provider for saved screenshots list
final savedScreenshotsProvider = FutureProvider<List<String>>((ref) async {
  final screenshotService = ref.watch(screenshotServiceProvider);
  return await screenshotService.getSavedScreenshots();
});

// Provider for refreshing screenshots
final screenshotsRefreshProvider = StateProvider<int>((ref) => 0);