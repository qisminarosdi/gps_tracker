import 'package:flutter/material.dart';

// Dialog shown when a previous tracking session can be recovered
class RecoveryDialog extends StatelessWidget {
  final int pointsCount;
  final int markersCount;
  final double distance;
  final VoidCallback onRestore;
  final VoidCallback onDiscard;

  const RecoveryDialog({
    super.key,
    required this.pointsCount,
    required this.markersCount,
    required this.distance,
    required this.onRestore,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF6B7FFF).withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 32,
                color: Color(0xFF6B7FFF),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Recover Previous Session?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              'We found a previous tracking session that wasn\'t properly saved.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    Icons.route_rounded,
                    'Points',
                    pointsCount.toString(),
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    Icons.location_on_rounded,
                    'Markers',
                    markersCount.toString(),
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    Icons.straighten_rounded,
                    'Distance',
                    _formatDistance(distance),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDiscard,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7FFF),
                      side: const BorderSide(
                        color: Color(0xFF6B7FFF),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Discard',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRestore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7FFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Restore',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7FFF)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }
}