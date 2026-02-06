import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/saved_screenshots_provider.dart';
import '../providers/providers.dart';
import '../models/walk_session.dart';
import '../views/walk_detail_screen.dart';

class ScreenshotsTab extends ConsumerWidget {
  const ScreenshotsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(screenshotsRefreshProvider);
    ref.watch(sessionsRefreshProvider);
    final screenshotsAsync = ref.watch(savedScreenshotsProvider);
    final sessionsAsync = ref.watch(walkSessionsProvider);

    return screenshotsAsync.when(
      data: (screenshots) {
        if (screenshots.isEmpty) {
          return _buildEmptyState();
        }
        return sessionsAsync.when(
          data: (sessions) =>
              _buildScreenshotList(context, ref, screenshots, sessions),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildScreenshotList(context, ref, screenshots, []),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
        ),
      ),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No screenshots yet',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          const Text(
            'Start walking to save route screenshots',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorRed,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Error loading screenshots',
            style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotList(
    BuildContext context,
    WidgetRef ref,
    List<String> screenshots,
    List<WalkSession> sessions,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: screenshots.length,
      itemBuilder: (context, index) {
        final screenshotPath = screenshots[index];
        // Find matching session
        final session = sessions.cast<WalkSession?>().firstWhere(
              (s) => s?.screenshotPath == screenshotPath,
              orElse: () => null,
            );
        return _buildScreenshotCard(context, ref, screenshotPath, session);
      },
    );
  }

  Widget _buildScreenshotCard(
    BuildContext context,
    WidgetRef ref,
    String screenshotPath,
    WalkSession? session,
  ) {
    final file = File(screenshotPath);
    final fileName = screenshotPath.split('/').last;
    final dateTime = session?.dateTime ?? _extractDateTime(fileName);
    final fileExists = file.existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      elevation: 2,
      child: InkWell(
        onTap: fileExists && session != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WalkDetailScreen(session: session),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: fileExists
                      ? Image.file(
                          file,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                size: 32,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            size: 32,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(dateTime),
                      style: AppTheme.sectionHeader.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(dateTime),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          size: 16,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session?.formattedDuration ?? '--',
                          style: AppTheme.bodySmall,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        const Icon(
                          Icons.straighten_rounded,
                          size: 16,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session?.formattedDistance ?? '--',
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                    // Show warning if file doesn't exist
                    if (!fileExists) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        'Screenshot file not found',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.errorRed,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                onPressed: () =>
                    _showDeleteConfirmation(context, ref, screenshotPath, session),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    String screenshotPath,
    WalkSession? session,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: AppTheme.dialogShape,
        title: const Text('Delete Screenshot', style: AppTheme.dialogTitle),
        content: Text(
          session != null
              ? 'Are you sure you want to delete this screenshot and session data?'
              : 'Are you sure you want to delete this screenshot?',
          style: AppTheme.dialogContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: AppTheme.textButton,
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final screenshotService = ref.read(screenshotServiceProvider);
              await screenshotService.deleteScreenshot(screenshotPath);

              // Delete session if it exists
              if (session != null) {
                final sessionService = ref.read(sessionStorageServiceProvider);
                await sessionService.deleteSession(session.id);
                ref.read(sessionsRefreshProvider.notifier).state++;
              }

              ref.read(screenshotsRefreshProvider.notifier).state++;
              ref.invalidate(savedScreenshotsProvider);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  DateTime _extractDateTime(String fileName) {
    try {
      final timestamp =
          fileName.replaceAll('path_', '').replaceAll('.png', '');
      return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    } catch (e) {
      return DateTime.now();
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}