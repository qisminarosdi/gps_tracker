import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/walk_session.dart';
import 'walk_map_viewer_screen.dart';

class WalkDetailScreen extends ConsumerStatefulWidget {
  final WalkSession session;

  const WalkDetailScreen({super.key, required this.session});

  @override
  ConsumerState<WalkDetailScreen> createState() => _WalkDetailScreenState();
}

class _WalkDetailScreenState extends ConsumerState<WalkDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Walk Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          children: [
            _buildCompletionCard(),
            const SizedBox(height: AppTheme.spacingL),
            _buildStatsCard(),
            const SizedBox(height: AppTheme.spacingL),
            _buildViewMapButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCard() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        children: [
          const Text(
            'Completed a walk',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          if (widget.session.screenshotPath != null)
            GestureDetector(
              onTap: () => _showFullScreenImage(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                child: Image.file(
                  File(widget.session.screenshotPath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            _formatDate(widget.session.dateTime),
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage() {
    if (widget.session.screenshotPath == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          imagePath: widget.session.screenshotPath!,
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.timer_rounded,
            widget.session.formattedDuration,
            'Duration',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.dividerColor,
          ),
          _buildStatItem(
            Icons.straighten_rounded,
            widget.session.formattedDistance,
            'Distance',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryPurple, size: 28),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          label,
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildViewMapButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.session.pathPoints.isEmpty
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WalkMapViewerScreen(session: widget.session),
                  ),
                );
              },
        style: AppTheme.largePrimaryButton,
        child: const Text('VIEW MAP'),
      ),
    );
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const _FullScreenImageViewer({
    required this.imagePath,
  });

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
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}