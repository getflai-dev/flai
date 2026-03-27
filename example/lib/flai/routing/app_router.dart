import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../providers/auth_provider.dart';
import '../flows/auth/auth_flow.dart';
import '../flows/chat/chat_experience_config.dart';
import '../flows/onboarding/onboarding_flow.dart';
import '../flows/sidebar/settings_config.dart';
import '../flows/sidebar/sidebar_config.dart';
import '../providers.dart';
import '../screens/chat_content.dart';
import '../screens/home_controller.dart';
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
        builder: (context, state) => _WiredHomePage(config: config),
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

// ── Wired Home Page ─────────────────────────────────────────────────────

/// Stateful wrapper that creates a [HomeController] and connects providers
/// to the [FlaiHomeScreen] UI. All frontend wiring is automatic — the
/// developer only needs to provide backend [AuthProvider], [AiProvider],
/// [StorageProvider], and optionally [VoiceProvider].
class _WiredHomePage extends StatefulWidget {
  const _WiredHomePage({required this.config});
  final AppScaffoldConfig config;

  @override
  State<_WiredHomePage> createState() => _WiredHomePageState();
}

class _WiredHomePageState extends State<_WiredHomePage> {
  HomeController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final providers = FlaiProviders.of(context);
    _controller = HomeController(
      storage: providers.storageProvider,
      ai: providers.aiProvider,
      auth: widget.config.authProvider,
      onError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      },
    );
    _controller!.addListener(_onChanged);
    _controller!.loadConversations();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onChanged);
    _controller?.dispose();
    super.dispose();
  }

  SettingsConfig get _effectiveSettingsConfig {
    final base = widget.config.settingsConfig;
    return SettingsConfig(
      drawerHeightRatio: base.drawerHeightRatio,
      showWorkspaceSwitcher: base.showWorkspaceSwitcher,
      sections: base.sections.map((section) {
        return SettingsSection(
          title: section.title,
          rows: section.rows.map((row) {
            if (row is NavigationRow && row.label == 'Sign Out') {
              return NavigationRow(
                icon: row.icon,
                label: row.label,
                onTap: () async {
                  await widget.config.authProvider.signOut();
                },
              );
            }
            return row;
          }).toList(),
        );
      }).toList(),
      infoItems: base.infoItems,
      appVersion: base.appVersion,
    );
  }

  ChatExperienceConfig get _effectiveChatConfig {
    final chatConfig = widget.config.chatExperienceConfig;
    if (widget.config.voiceProvider != null && !chatConfig.enableVoice) {
      return ChatExperienceConfig(
        assistantName: chatConfig.assistantName,
        assistantAvatar: chatConfig.assistantAvatar,
        greeting: chatConfig.greeting,
        greetingSubtitle: chatConfig.greetingSubtitle,
        composerPlaceholder: chatConfig.composerPlaceholder,
        composerConfig: chatConfig.composerConfig,
        availableModels: chatConfig.availableModels,
        enableVoice: true,
        enableGhostMode: chatConfig.enableGhostMode,
        enablePerMessageModelSwitch: chatConfig.enablePerMessageModelSwitch,
      );
    }
    return chatConfig;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    if (ctrl == null) return const SizedBox.shrink();

    final chatConfig = _effectiveChatConfig;
    final hasActiveChat = ctrl.activeConversationId != null;

    final baseSidebar = widget.config.sidebarConfig ??
        SidebarConfig(appName: widget.config.appTitle);

    return FlaiHomeScreen(
      sidebarConfig: SidebarConfig(
        appName: baseSidebar.appName,
        appLogo: baseSidebar.appLogo,
        navItems: baseSidebar.navItems,
        enableSearch: baseSidebar.enableSearch,
        topNavActions: baseSidebar.topNavActions,
        settingsConfig: baseSidebar.settingsConfig,
        onNewChat: baseSidebar.onNewChat,
        onConversationTap: baseSidebar.onConversationTap,
        onConversationStar: baseSidebar.onConversationStar ?? (item) => ctrl.starConversation(item),
        onConversationRename: baseSidebar.onConversationRename ?? (item, title) => ctrl.renameConversation(item, title),
        onConversationShare: baseSidebar.onConversationShare,
        onConversationDelete: baseSidebar.onConversationDelete ?? (item) => ctrl.deleteConversation(item),
      ),
      chatExperienceConfig: chatConfig,
      settingsConfig: _effectiveSettingsConfig,
      userProfile: ctrl.userProfile,
      conversations: ctrl.conversations,
      starredConversations: ctrl.starred,
      activeConversationId: ctrl.activeConversationId,
      onNewChat: () => ctrl.newChat(),
      onSendMessage: (text) => ctrl.sendMessage(text),
      onConversationTap: (item) => ctrl.selectConversation(item),
      chatContent: hasActiveChat
          ? FlaiChatContent(
              messages: ctrl.messages,
              config: chatConfig,
              onSend: (text) => ctrl.sendMessage(text),
              isStreaming: ctrl.isStreaming,
            )
          : null,
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
