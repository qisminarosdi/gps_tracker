import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../widgets/screenshots_tab.dart';
import '../widgets/recordings_tab.dart';

// Walking History screen with tabs for screenshots and recordings
class WalkingHistoryScreen extends ConsumerStatefulWidget {
  const WalkingHistoryScreen({super.key});

  @override
  ConsumerState<WalkingHistoryScreen> createState() =>
      _WalkingHistoryScreenState();
}

class _WalkingHistoryScreenState extends ConsumerState<WalkingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Walking History'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryPurple,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primaryPurple,
          indicatorWeight: 3,
          labelStyle: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTheme.bodyMedium,
          tabs: const [
            Tab(
              icon: Icon(Icons.photo_library_rounded),
              text: 'Screenshots',
            ),
            Tab(
              icon: Icon(Icons.videocam_rounded),
              text: 'Recordings',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ScreenshotsTab(),
          RecordingsTab(),
        ],
      ),
    );
  }
}