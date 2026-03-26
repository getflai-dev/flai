import 'package:flutter/material.dart';
import '../flai/flai.dart';

class MockTypingIndicator extends StatefulWidget {
  const MockTypingIndicator({super.key});

  @override
  State<MockTypingIndicator> createState() => _MockTypingIndicatorState();
}

class _MockTypingIndicatorState extends State<MockTypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((c) {
      return Tween<double>(
        begin: 0,
        end: -6,
      ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

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
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _animations[i],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animations[i].value),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: theme.colors.mutedForeground.withValues(
                        alpha: 0.6,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
