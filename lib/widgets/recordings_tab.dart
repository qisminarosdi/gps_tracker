import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../models/walk_session.dart';

// Tab showing all recorded walk sessions with video playback
class RecordingsTab extends ConsumerWidget {
  const RecordingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch sessions to get recordings with metadata
    ref.watch(sessionsRefreshProvider);
    final sessionsAsync = ref.watch(walkSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        // Filter sessions that have recording paths
        final sessionsWithRecordings = sessions
            .where((s) => s.recordingPath != null && s.recordingPath!.isNotEmpty)
            .toList();

        if (sessionsWithRecordings.isEmpty) {
          return _buildEmptyState();
        }

        return _buildRecordingsList(context, ref, sessionsWithRecordings);
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
          Icon(Icons.videocam_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No recordings yet',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          const Text(
            'Start walking to record your sessions',
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
            'Error loading recordings',
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

  Widget _buildRecordingsList(
    BuildContext context,
    WidgetRef ref,
    List<WalkSession> sessions,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _RecordingCard(
          session: session,
          onDelete: () async {
            // Delete the recording file
            if (session.recordingPath != null) {
              final service = ref.read(screenRecorderServiceProvider);
              await service.deleteRecording(session.recordingPath!);
            }

            // Delete the session from storage
            final sessionService = ref.read(sessionStorageServiceProvider);
            await sessionService.deleteSession(session.id);

            // Refresh the list
            ref.read(sessionsRefreshProvider.notifier).state++;
            ref.invalidate(walkSessionsProvider);
          },
        );
      },
    );
  }
}

// Card displaying recording info with playback and delete options
class _RecordingCard extends StatelessWidget {
  final WalkSession session;
  final VoidCallback onDelete;

  const _RecordingCard({
    required this.session,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final recordingPath = session.recordingPath;
    if (recordingPath == null) return const SizedBox.shrink();

    final file = File(recordingPath);
    final fileExists = file.existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      elevation: 2,
      child: InkWell(
        onTap: fileExists
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _VideoPlayerScreen(filePath: recordingPath),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              // Video icon indicator
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(
                  fileExists ? Icons.videocam : Icons.videocam_off,
                  color: fileExists ? AppTheme.primaryPurple : Colors.grey,
                  size: 40,
                ),
              ),

              const SizedBox(width: AppTheme.spacingM),

              // Session metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(session.dateTime),
                      style: AppTheme.sectionHeader.copyWith(fontSize: 18),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _formatTime(session.dateTime),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingS),

                    // Duration, distance, and file size
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          size: 16,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.formattedDuration,
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
                          session.formattedDistance,
                          style: AppTheme.bodySmall,
                        ),

                        const SizedBox(width: AppTheme.spacingM),

                        if (fileExists) ...[
                          const Icon(
                            Icons.storage,
                            size: 16,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatFileSize(file.lengthSync()),
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),

                    // Warning for missing files
                    if (!fileExists) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        'Recording file not found',
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
                onPressed: () => _showDeleteConfirmation(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: AppTheme.dialogShape,
        title: const Text('Delete Recording', style: AppTheme.dialogTitle),
        content: const Text(
          'Are you sure you want to delete this recording and session data?',
          style: AppTheme.dialogContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: AppTheme.textButton,
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

// Fullscreen video player with play/pause control
class _VideoPlayerScreen extends StatefulWidget {
  final String filePath;

  const _VideoPlayerScreen({required this.filePath});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(File(widget.filePath));

    try {
      await _controller.initialize();
      setState(() => _isInitialized = true);
      _controller.play();
      _controller.setLooping(true);
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recording', style: TextStyle(color: AppTheme.white)),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
              ),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryPurple,
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppTheme.white,
              ),
            )
          : null,
    );
  }
}