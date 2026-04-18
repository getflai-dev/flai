import 'providers/auth_provider.dart';
import 'providers/brain_provider.dart';
import 'providers/connections_provider.dart';
import 'providers/storage_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/voice_provider.dart';
import 'core/theme/flai_theme.dart';
import 'flows/auth/auth_flow_config.dart';
import 'flows/onboarding/onboarding_config.dart';
import 'flows/chat/chat_experience_config.dart';
import 'flows/sidebar/sidebar_config.dart';
import 'flows/sidebar/settings_config.dart';

/// Bundles every dependency and configuration the app scaffold needs.
///
/// Pass an instance to the top-level `FlaiApp` widget. Only [authProvider] is
/// required — everything else has sensible defaults or is optional.
///
/// ```dart
/// final config = AppScaffoldConfig(
///   authProvider: myAuthProvider,
///   aiProvider: myAiProvider,
///   theme: FlaiThemeData.dark(),
/// );
/// ```
class AppScaffoldConfig {
  /// The authentication provider used for sign-in, sign-up, and session
  /// management. Required — there is no default implementation.
  final AuthProvider authProvider;

  /// The persistence layer for conversations and messages.
  ///
  /// If null, [FlaiProviders] will create an [InMemoryStorageProvider] so the
  /// app works out of the box during development.
  final StorageProvider? storageProvider;

  /// The AI chat provider for streaming completions and tool use.
  ///
  /// If null, the chat screen will display an "AI provider not configured"
  /// placeholder.
  final AiProvider? aiProvider;

  /// The voice provider for speech-to-text and text-to-speech.
  ///
  /// If null, voice features are disabled regardless of
  /// [ChatExperienceConfig.enableVoice].
  final VoiceProvider? voiceProvider;

  /// The Brain provider that backs the Documents and Memory tabs.
  ///
  /// If null, the Brain nav item is hidden from the sidebar.
  final BrainProvider? brainProvider;

  /// The Connections provider that powers the Settings → Connections page.
  ///
  /// If null, the Connections page renders an empty state.
  final ConnectionsProvider? connectionsProvider;

  /// Theme data applied to the entire app.
  ///
  /// If null, `FlaiApp` defaults to [FlaiThemeData.dark()].
  final FlaiThemeData? theme;

  /// Configuration for the authentication flow screens (social providers,
  /// branding, legal links).
  final AuthFlowConfig authFlowConfig;

  /// Configuration for the post-auth onboarding flow.
  ///
  /// If null, onboarding is skipped entirely and the user proceeds straight
  /// to the main chat experience after authentication.
  final OnboardingConfig? onboardingConfig;

  /// Configuration for the chat experience (assistant name, composer options,
  /// model selector, feature flags).
  final ChatExperienceConfig chatExperienceConfig;

  /// Configuration for the sidebar navigation drawer.
  ///
  /// If null, the sidebar uses a minimal default layout. Typically set at
  /// runtime once the user profile and conversation list are available.
  final SidebarConfig? sidebarConfig;

  /// Configuration for the settings sheet (sections, toggles, info items).
  final SettingsConfig settingsConfig;

  /// The application title shown in the OS task switcher.
  final String appTitle;

  /// Whether to show a splash screen before the auth flow.
  ///
  /// Set to `false` to skip the splash and navigate directly to the login
  /// screen on cold start.
  final bool showSplash;

  /// Creates an [AppScaffoldConfig].
  const AppScaffoldConfig({
    required this.authProvider,
    this.storageProvider,
    this.aiProvider,
    this.voiceProvider,
    this.brainProvider,
    this.connectionsProvider,
    this.theme,
    this.authFlowConfig = const AuthFlowConfig(),
    this.onboardingConfig,
    this.chatExperienceConfig = const ChatExperienceConfig(),
    this.sidebarConfig,
    this.settingsConfig = const SettingsConfig(),
    this.appTitle = 'FlAI Chat',
    this.showSplash = true,
  });
}
