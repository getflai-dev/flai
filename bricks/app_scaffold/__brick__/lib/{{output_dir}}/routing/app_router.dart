import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../providers/auth_provider.dart';
import '../flows/auth/auth_flow.dart';
import '../flows/onboarding/onboarding_flow.dart';
import '../flows/sidebar/sidebar_config.dart';
import '../screens/home_screen.dart';

/// Route name constants for the app scaffold.
///
/// Use these with [GoRouter.goNamed] for type-safe navigation:
/// ```dart
/// context.goNamed(AppRoutes.home);
/// context.goNamed(AppRoutes.auth);
/// ```
abstract final class AppRoutes {
  /// Splash screen.
  static const splash = 'splash';

  /// Authentication flow.
  static const auth = 'auth';

  /// Post-auth onboarding flow.
  static const onboarding = 'onboarding';

  /// Main home screen (sidebar + chat).
  static const home = 'home';
}

/// Route path constants.
abstract final class AppPaths {
  /// Splash screen path.
  static const splash = '/splash';

  /// Authentication flow path.
  static const auth = '/auth';

  /// Post-auth onboarding flow path.
  static const onboarding = '/onboarding';

  /// Main home screen path.
  static const home = '/';
}

/// Creates the [GoRouter] for the app scaffold.
///
/// Handles four top-level flows: splash, auth, onboarding, and main home.
/// Listens to [AuthProvider.authStateChanges] to redirect between auth
/// screens and the main app. When the user is unauthenticated, all non-auth
/// routes redirect to the auth flow. When authenticated, auth and splash
/// routes redirect to home (or onboarding if configured).
///
/// ```dart
/// final router = createAppRouter(
///   config: AppScaffoldConfig(authProvider: myAuthProvider),
/// );
/// ```
GoRouter createAppRouter({required AppScaffoldConfig config}) {
  return GoRouter(
    initialLocation:
        config.showSplash ? AppPaths.splash : AppPaths.auth,
    refreshListenable: _AuthStateNotifier(config.authProvider),
    redirect: (context, state) {
      final user = config.authProvider.currentUser;
      final location = state.matchedLocation;

      final isAuthRoute = location == AppPaths.auth;
      final isSplashRoute = location == AppPaths.splash;
      final isOnboardingRoute = location == AppPaths.onboarding;

      // Not authenticated and not on auth or splash route — go to auth.
      if (user == null && !isAuthRoute && !isSplashRoute) {
        return AppPaths.auth;
      }

      // Authenticated but on auth or splash route — move forward.
      if (user != null && (isAuthRoute || isSplashRoute)) {
        if (config.onboardingConfig != null && !isOnboardingRoute) {
          return AppPaths.onboarding;
        }
        return AppPaths.home;
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppPaths.splash,
        name: AppRoutes.splash,
        builder: (context, state) => FlaiSplashScreen(
          logo: config.onboardingConfig?.splashLogo,
          onReady: () => GoRouter.of(context).go(AppPaths.auth),
        ),
      ),

      // Auth
      GoRoute(
        path: AppPaths.auth,
        name: AppRoutes.auth,
        builder: (context, state) => _AuthFlowPage(config: config),
      ),

      // Onboarding
      GoRoute(
        path: AppPaths.onboarding,
        name: AppRoutes.onboarding,
        builder: (context, state) =>
            _OnboardingFlowPage(config: config),
      ),

      // Home
      GoRoute(
        path: AppPaths.home,
        name: AppRoutes.home,
        builder: (context, state) => FlaiHomeScreen(
          sidebarConfig: config.sidebarConfig ??
              SidebarConfig(appName: config.appTitle),
          chatExperienceConfig: config.chatExperienceConfig,
          settingsConfig: config.settingsConfig,
        ),
      ),
    ],
  );
}

// ── Auth Flow Page ──────────────────────────────────────────────────────

/// Private page that hosts the auth flow state machine.
///
/// Creates an [AuthController] and uses [ListenableBuilder] to switch
/// between auth screens based on the controller's current screen.
class _AuthFlowPage extends StatefulWidget {
  const _AuthFlowPage({required this.config});

  final AppScaffoldConfig config;

  @override
  State<_AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends State<_AuthFlowPage> {
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthController(
      provider: widget.config.authProvider,
      config: widget.config.authFlowConfig,
      onAuthenticated: (user) {
        if (widget.config.onboardingConfig != null) {
          context.go(AppPaths.onboarding);
        } else {
          context.go(AppPaths.home);
        }
      },
      onGuestContinue: () => context.go(AppPaths.home),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return switch (_controller.currentScreen) {
          AuthScreen.loginLanding =>
            FlaiLoginLanding(controller: _controller),
          AuthScreen.emailEntry =>
            FlaiEmailEntry(controller: _controller),
          AuthScreen.passwordEntry =>
            FlaiPasswordEntry(controller: _controller),
          AuthScreen.forgotPassword =>
            FlaiForgotPassword(controller: _controller),
          AuthScreen.verificationCode =>
            FlaiVerificationCode(controller: _controller),
          AuthScreen.resetPassword =>
            FlaiResetPassword(controller: _controller),
        };
      },
    );
  }
}

// ── Onboarding Flow Page ────────────────────────────────────────────────

/// Private page that hosts the onboarding flow state machine.
///
/// Creates an [OnboardingController] wrapping the consumer's config and
/// uses [ListenableBuilder] to switch between onboarding step screens.
class _OnboardingFlowPage extends StatefulWidget {
  const _OnboardingFlowPage({required this.config});

  final AppScaffoldConfig config;

  @override
  State<_OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<_OnboardingFlowPage> {
  late final OnboardingController _controller;

  @override
  void initState() {
    super.initState();
    final onboardingConfig = widget.config.onboardingConfig!;
    _controller = OnboardingController(
      config: OnboardingConfig(
        splashLogo: onboardingConfig.splashLogo,
        steps: onboardingConfig.steps,
        revealLogo: onboardingConfig.revealLogo,
        revealGradient: onboardingConfig.revealGradient,
        onComplete: (result) {
          onboardingConfig.onComplete(result);
          if (context.mounted) context.go(AppPaths.home);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final step = _controller.currentStep;
        if (step == null) return const SizedBox.shrink();

        return switch (step) {
          NamingStep() =>
            FlaiNamingScreen(controller: _controller, step: step),
          MultiSelectStep() =>
            FlaiMultiSelectScreen(controller: _controller, step: step),
          CustomStep() =>
            FlaiCustomStepScreen(controller: _controller, step: step),
          RevealStep() =>
            FlaiRevealScreen(controller: _controller, step: step),
        };
      },
    );
  }
}

// ── Auth State Notifier ─────────────────────────────────────────────────

/// Bridges [AuthProvider.authStateChanges] into a [ChangeNotifier] so
/// [GoRouter] can listen for auth state changes and trigger redirects.
class _AuthStateNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthUser?> _subscription;

  _AuthStateNotifier(AuthProvider authProvider) {
    _subscription = authProvider.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
