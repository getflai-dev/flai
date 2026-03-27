import 'package:flutter/material.dart';
import '../../../core/theme/flai_theme.dart';

/// Full-screen splash with a centered logo and subtle pulse animation.
///
/// This screen is standalone — it does not depend on [OnboardingController].
/// Use [onReady] to signal when the app has finished loading and is ready
/// to transition (e.g., to auth or onboarding).
class FlaiSplashScreen extends StatefulWidget {
  const FlaiSplashScreen({
    super.key,
    this.logo,
    this.onReady,
  });

  /// Logo widget displayed at center. If null, shows app name text.
  final Widget? logo;

  /// Called after the splash has been visible for at least [minDuration].
  /// Use this to trigger navigation away from the splash.
  final VoidCallback? onReady;

  /// Minimum time the splash stays visible.
  static const minDuration = Duration(milliseconds: 1200);

  @override
  State<FlaiSplashScreen> createState() => _FlaiSplashScreenState();
}

class _FlaiSplashScreenState extends State<FlaiSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(FlaiSplashScreen.minDuration, () {
      if (mounted) widget.onReady?.call();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: Center(
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: widget.logo ??
              Text(
                'FlAI',
                style: theme.typography.xxl.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
        ),
      ),
    );
  }
}
