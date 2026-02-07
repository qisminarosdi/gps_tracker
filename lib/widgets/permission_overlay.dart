import 'package:flutter/material.dart';

/// overlay shown when location permissions need to be configured
class PermissionOverlay extends StatelessWidget {
  final bool locationServicesDisabled;
  final bool permissionDenied;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onOpenAppSettings;

  const PermissionOverlay({
    super.key,
    required this.locationServicesDisabled,
    required this.permissionDenied,
    required this.onOpenLocationSettings,
    required this.onOpenAppSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7FFF).withValues(alpha:0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    size: 40,
                    color: Color(0xFF6B7FFF),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  locationServicesDisabled
                      ? 'Location Services Disabled'
                      : 'Location Permission Required',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Description
                Text(
                  locationServicesDisabled
                      ? 'Please enable location services in your device settings to use GPS tracking.'
                      : 'This app needs location permission to track your path. Please grant permission in your device settings.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: locationServicesDisabled
                        ? onOpenLocationSettings
                        : onOpenAppSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7FFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.settings, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          locationServicesDisabled
                              ? 'Open Location Settings'
                              : 'Open App Settings',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}