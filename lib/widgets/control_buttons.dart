import 'package:flutter/material.dart';
import '../models/tracking_state.dart';

/// Control buttons for tracking operations
class ControlButtons extends StatelessWidget {
  final TrackingState state;
  final GlobalKey mapKey;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onAddMarker;

  const ControlButtons({
    super.key,
    required this.state,
    required this.mapKey,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onAddMarker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Start/Stop Button
          _buildMainButton(),

          // Marker Button
          _buildMarkerButton(),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return Expanded(
      flex: 2,
      child: _AnimatedButton(
        onPressed: state.isRecording ? onStopRecording : onStartRecording,
        backgroundColor: state.isRecording
            ? const Color(0xFFFF6B6B)
            : const Color(0xFF6B7FFF),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.isRecording ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              state.isRecording ? 'Stop' : 'Start',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerButton() {
    final bool isEnabled = state.isRecording && state.pathPoints.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: _AnimatedButton(
        onPressed: isEnabled ? onAddMarker : null,
        backgroundColor: isEnabled
            ? const Color(0xFFFF9F6B)
            : const Color(0xFFE0E0E0),
        child: Icon(
          Icons.add_location_rounded,
          color: isEnabled ? Colors.white : const Color(0xFFBDBDBD),
          size: 28,
        ),
      ),
    );
  }
}

/// Animated button with press effect
class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;

  const _AnimatedButton({
    required this.onPressed,
    required this.child,
    required this.backgroundColor,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => _controller.forward()
          : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: widget.onPressed != null
          ? () => _controller.reverse()
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.onPressed != null
                ? [
                    BoxShadow(
                      color: widget.backgroundColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
