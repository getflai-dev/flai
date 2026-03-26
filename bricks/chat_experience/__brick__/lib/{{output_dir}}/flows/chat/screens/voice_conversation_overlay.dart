import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';

/// Full-screen overlay for continuous voice conversation mode.
///
/// Displays an animated orb that pulses while listening or speaking.
/// Tap anywhere on the overlay to end the conversation.
class FlaiVoiceConversationOverlay extends StatefulWidget {
  /// Called when the user taps anywhere to end the conversation.
  final VoidCallback onEnd;

  /// Whether the AI is currently listening to the user.
  final bool isListening;

  /// Whether the AI is currently speaking a response.
  final bool isSpeaking;

  /// Optional gradient colors for the orb. Defaults to primary/secondary tones
  /// derived from the current [FlaiTheme].
  final List<Color>? gradientColors;

  /// Creates a [FlaiVoiceConversationOverlay].
  const FlaiVoiceConversationOverlay({
    super.key,
    required this.onEnd,
    this.isListening = false,
    this.isSpeaking = false,
    this.gradientColors,
  });

  @override
  State<FlaiVoiceConversationOverlay> createState() =>
      _FlaiVoiceConversationOverlayState();
}

class _FlaiVoiceConversationOverlayState
    extends State<FlaiVoiceConversationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _updateAnimation();
  }

  @override
  void didUpdateWidget(FlaiVoiceConversationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isListening != widget.isListening ||
        oldWidget.isSpeaking != widget.isSpeaking) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.isListening) {
      // Active pulse: scales between 0.85 and 1.15
      _scaleAnimation = Tween<double>(
        begin: 0.85,
        end: 1.15,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );
    } else if (widget.isSpeaking) {
      // Subtle pulse: scales between 1.0 and 1.05
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 1.05,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );
    } else {
      // Idle: static at 1.0
      _scaleAnimation = ConstantTween<double>(1.0).animate(
        _animationController,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _statusText {
    if (widget.isListening) return 'Listening...';
    if (widget.isSpeaking) return 'Speaking...';
    return 'Ready';
  }

  IconData get _statusIcon {
    if (widget.isListening) return Icons.mic_rounded;
    if (widget.isSpeaking) return Icons.volume_up_rounded;
    return Icons.mic_none_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    final orbColors = widget.gradientColors ??
        [
          theme.colors.primary,
          theme.colors.primary.withValues(alpha: 0.6),
        ];

    return GestureDetector(
      onTap: widget.onEnd,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.colors.background,
        body: Column(
          children: [
            const Spacer(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated orb
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: orbColors,
                          center: Alignment.center,
                          radius: 0.85,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: orbColors.first.withValues(alpha: 0.45),
                            blurRadius: 36,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: orbColors.first.withValues(alpha: 0.20),
                            blurRadius: 60,
                            spreadRadius: 16,
                          ),
                        ],
                      ),
                      child: Icon(
                        _statusIcon,
                        color: theme.colors.primaryForeground,
                        size: 40,
                      ),
                    ),
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // Status text
                  Text(
                    _statusText,
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Instruction text
            Padding(
              padding: EdgeInsets.only(bottom: theme.spacing.xl),
              child: Text(
                'Tap anywhere to end conversation',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
