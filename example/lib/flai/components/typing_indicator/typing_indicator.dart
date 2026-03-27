import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';

/// An animated three-dot typing indicator that shows the AI is generating
/// a response.
///
/// Styled as an assistant bubble (left-aligned, matching assistant message
/// shape and background). Each dot bounces up with a staggered delay,
/// creating a wave-like animation.
class FlaiTypingIndicator extends StatefulWidget {
  /// Diameter of each dot.
  final double dotSize;

  /// Override color for the dots. Defaults to [FlaiColors.mutedForeground].
  final Color? dotColor;

  /// How far each dot bounces upward (in logical pixels).
  final double bounceHeight;

  const FlaiTypingIndicator({
    super.key,
    this.dotSize = 7.0,
    this.dotColor,
    this.bounceHeight = 6.0,
  });

  @override
  State<FlaiTypingIndicator> createState() => _FlaiTypingIndicatorState();
}

class _FlaiTypingIndicatorState extends State<FlaiTypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  static const _dotCount = 3;
  static const _animationDuration = Duration(milliseconds: 600);
  static const _staggerDelay = Duration(milliseconds: 180);

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(_dotCount, (_) {
      return AnimationController(duration: _animationDuration, vsync: this);
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: -widget.bounceHeight,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    // Start each dot with a staggered delay.
    for (var i = 0; i < _dotCount; i++) {
      Future.delayed(_staggerDelay * i, () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final effectiveDotColor =
        widget.dotColor ?? theme.colors.mutedForeground.withValues(alpha: 0.6);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: theme.spacing.md,
          right: theme.spacing.xl,
          bottom: theme.spacing.sm,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: theme.colors.assistantBubble,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(theme.radius.lg),
            topRight: Radius.circular(theme.radius.lg),
            bottomLeft: Radius.circular(theme.radius.sm),
            bottomRight: Radius.circular(theme.radius.lg),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_dotCount, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animations[index].value),
                  child: child,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  color: effectiveDotColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
