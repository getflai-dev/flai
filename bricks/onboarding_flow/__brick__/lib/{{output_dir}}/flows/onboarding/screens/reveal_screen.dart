import 'package:flutter/material.dart';
import '../../../core/theme/flai_theme.dart';
import '../onboarding_config.dart';
import '../onboarding_controller.dart';
import '../widgets/typing_text.dart';

/// Celebratory reveal screen that animates the AI assistant logo into view,
/// types out the assistant name, and then auto-transitions to the next step.
///
/// Animation sequence:
/// 1. Logo scales up with [Curves.easeOutBack] (800 ms).
/// 2. Once the scale completes, the assistant name is typed out character by
///    character using [TypingText].
/// 3. After typing finishes, a subtitle fades in and a hold timer fires
///    [RevealStep.holdDuration] later, calling [controller.next()].
class FlaiRevealScreen extends StatefulWidget {
  const FlaiRevealScreen({
    super.key,
    required this.controller,
    required this.step,
  });

  final OnboardingController controller;
  final RevealStep step;

  @override
  State<FlaiRevealScreen> createState() => _FlaiRevealScreenState();
}

class _FlaiRevealScreenState extends State<FlaiRevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  bool _showName = false;
  bool _nameComplete = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward().then((_) {
      if (mounted) setState(() => _showName = true);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onNameComplete() {
    if (!mounted) return;
    setState(() => _nameComplete = true);
    Future.delayed(widget.step.holdDuration, () {
      if (mounted) widget.controller.next();
    });
  }

  String get _title =>
      (widget.step.title ?? 'Meet {name}')
          .replaceAll('{name}', widget.controller.assistantName);

  String get _subtitle =>
      widget.step.subtitle ?? 'Your AI assistant is ready';

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final config = widget.controller.config;

    // Determine glow base color from the first gradient color.
    final glowColor = config.revealGradient.isNotEmpty
        ? config.revealGradient.first
        : theme.colors.primary;

    // The logo widget to display.
    final logoWidget = config.revealLogo ??
        config.splashLogo ??
        _DefaultRevealLogo(gradient: config.revealGradient);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Animated logo ──────────────────────────────────────
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final glow = _glowAnimation.value;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withAlpha(
                            (0.4 * glow * 255).round(),
                          ),
                          blurRadius: 40.0 * glow,
                          spreadRadius: 8.0 * glow,
                        ),
                      ],
                    ),
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: logoWidget,
              ),

              SizedBox(height: theme.spacing.xxl),

              // ── Typing name ────────────────────────────────────────
              if (_showName)
                TypingText(
                  text: _title,
                  style: theme.typography.xl.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                  onComplete: _onNameComplete,
                ),

              SizedBox(height: theme.spacing.md),

              // ── Subtitle fade-in ───────────────────────────────────
              AnimatedOpacity(
                opacity: _nameComplete ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Default logo shown when neither [OnboardingConfig.revealLogo] nor
/// [OnboardingConfig.splashLogo] are provided.
///
/// Renders a gradient circle with an auto_awesome star icon.
class _DefaultRevealLogo extends StatelessWidget {
  const _DefaultRevealLogo({required this.gradient});

  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final colors = gradient.length >= 2
        ? gradient
        : [const Color(0xFF818CF8), const Color(0xFF34D399)];

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 48,
      ),
    );
  }
}
