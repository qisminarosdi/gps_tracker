import 'package:flutter/material.dart';
import '../models/tracking_state.dart';

/// widget showing GPS status and accuracy
class GpsStatusIndicator extends StatelessWidget {
  final TrackingState state;

  const GpsStatusIndicator({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.isRecording) return const SizedBox.shrink();

    final accuracyStatus = state.accuracyStatus;
    final accuracy = state.lastGpsAccuracy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(accuracyStatus),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(accuracyStatus),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            accuracy != null ? '±${accuracy.toStringAsFixed(0)}m' : 'GPS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(GpsAccuracyStatus status) {
    switch (status) {
      case GpsAccuracyStatus.excellent:
        return const Color(0xFF4CAF50); // Green
      case GpsAccuracyStatus.good:
        return const Color(0xFF8BC34A); // Light green
      case GpsAccuracyStatus.fair:
        return const Color(0xFFFFA726); // Orange
      case GpsAccuracyStatus.poor:
        return const Color(0xFFFF6B6B); // Red
      case GpsAccuracyStatus.unknown:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  IconData _getIcon(GpsAccuracyStatus status) {
    switch (status) {
      case GpsAccuracyStatus.excellent:
      case GpsAccuracyStatus.good:
        return Icons.gps_fixed;
      case GpsAccuracyStatus.fair:
        return Icons.gps_not_fixed;
      case GpsAccuracyStatus.poor:
      case GpsAccuracyStatus.unknown:
        return Icons.gps_off;
    }
  }
}