import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';

/// An inline push-to-talk voice recorder widget.
///
/// Shows an animated waveform, an elapsed timer, and stop/cancel controls.
class VoiceRecorder extends StatefulWidget {
  /// Called when the user stops recording.
  final VoidCallback? onStop;

  /// Called when the user cancels recording.
  final VoidCallback? onCancel;

  /// Creates a [VoiceRecorder].
  const VoiceRecorder({super.key, this.onStop, this.onCancel});

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Timer _timer;
  int _seconds = 0;

  static const int _barCount = 12;

  // Heights vary by bar index to produce a natural-looking waveform shape.
  static const List<double> _barBaseHeights = [
    6,
    10,
    14,
    18,
    22,
    20,
    24,
    18,
    14,
    10,
    8,
    6,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.sm,
        vertical: theme.spacing.xs,
      ),
      child: Row(
        children: [
          // Cancel button (44x44 touch target)
          if (widget.onCancel != null)
            GestureDetector(
              onTap: widget.onCancel,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    Icons.close,
                    color: theme.colors.mutedForeground,
                    size: 20,
                  ),
                ),
              ),
            ),

          // Animated waveform bars
          AnimatedBuilder(
            animation: _animationController,
            builder: (_, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(_barCount, (index) {
                  final phase = (index / _barCount);
                  final animValue = (_animationController.value + phase) % 1.0;
                  final base = _barBaseHeights[index];
                  final height = base + (animValue * base * 0.6);
                  return Container(
                    width: 3,
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: theme.colors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              );
            },
          ),

          SizedBox(width: theme.spacing.sm),

          // Timer text
          Text(
            _formatTime(_seconds),
            style: theme.typography.sm.copyWith(
              color: theme.colors.foreground,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          const Spacer(),

          // Stop button (44x44 touch target, 36x36 visual)
          GestureDetector(
            onTap: widget.onStop,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stop, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
