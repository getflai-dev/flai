import 'package:flutter/material.dart';

import '../core/theme/flai_theme.dart';
import '../flows/chat/chat_experience_config.dart';
import '../flows/chat/screens/empty_chat_state.dart';
import '../flows/chat/voice_controller.dart';
import '../flows/chat/widgets/composer_v2.dart';
import '../flows/sidebar/screens/sidebar_drawer.dart';
import '../flows/sidebar/settings_config.dart';
import '../flows/sidebar/sidebar_config.dart';
import '../flows/sidebar/widgets/top_nav_bar.dart';
import '../providers.dart';

/// The main home screen displayed after authentication and onboarding.
///
/// Composes the sidebar navigation drawer with the chat content area.
/// When no conversation is active, shows [FlaiEmptyChatState] with a
/// composer at the bottom so users can start a new conversation.
/// When a conversation is active, shows the consumer-provided [chatContent].
class FlaiHomeScreen extends StatefulWidget {
  /// Sidebar navigation configuration (app name, nav items, callbacks).
  final SidebarConfig sidebarConfig;

  /// Chat experience configuration (assistant name, greeting, avatar).
  final ChatExperienceConfig chatExperienceConfig;

  /// Settings sheet configuration.
  final SettingsConfig settingsConfig;

  /// The signed-in user's profile, displayed in the sidebar footer.
  final UserProfile? userProfile;

  /// The list of recent conversations shown in the sidebar.
  final List<ConversationItem> conversations;

  /// The list of starred conversations shown in the sidebar.
  final List<ConversationItem> starredConversations;

  /// The ID of the currently active conversation, if any.
  final String? activeConversationId;

  /// The chat widget to display in the content area.
  ///
  /// When null, [FlaiEmptyChatState] is shown with a composer.
  /// When provided, it is expected to include its own message composer.
  final Widget? chatContent;

  /// Called when the user sends a message from the empty chat state.
  ///
  /// Use this to create a new conversation and navigate to the chat view.
  final ValueChanged<String>? onSendMessage;

  /// Called when the user taps the "New Chat" button.
  final VoidCallback? onNewChat;

  /// Called when the user taps a conversation in the sidebar.
  final void Function(ConversationItem)? onConversationTap;

  /// Called when the user opens the settings sheet.
  final VoidCallback? onOpenSettings;

  /// Called when the user changes the chat mode (Quick Answer, Autopilot, etc.)
  /// from the composer's mode pill. The selected mode id is also retained
  /// internally so the pill stays in sync without consumer wiring.
  final ValueChanged<ChatMode>? onModeChanged;

  /// The initial chat-mode id to highlight in the composer's mode pill.
  /// When null, the first entry in
  /// [ChatExperienceConfig.availableModes] is used.
  final String? initialModeId;

  /// Creates a [FlaiHomeScreen].
  const FlaiHomeScreen({
    super.key,
    required this.sidebarConfig,
    required this.chatExperienceConfig,
    required this.settingsConfig,
    this.userProfile,
    this.conversations = const [],
    this.starredConversations = const [],
    this.activeConversationId,
    this.chatContent,
    this.onSendMessage,
    this.onNewChat,
    this.onConversationTap,
    this.onOpenSettings,
    this.onModeChanged,
    this.initialModeId,
  });

  @override
  State<FlaiHomeScreen> createState() => _FlaiHomeScreenState();
}

class _FlaiHomeScreenState extends State<FlaiHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  FlaiVoiceController? _voiceController;
  String? _currentModeId;
  String? _currentSearchModeId;

  @override
  void initState() {
    super.initState();
    final modes = widget.chatExperienceConfig.availableModes;
    _currentModeId =
        widget.initialModeId ?? (modes.isNotEmpty ? modes.first.id : null);
    final searchModes = widget.chatExperienceConfig.availableSearchModes;
    _currentSearchModeId = searchModes.isNotEmpty ? searchModes.first.id : null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initVoiceController();
  }

  void _initVoiceController() {
    if (_voiceController != null) return;
    if (!widget.chatExperienceConfig.enableVoice) return;

    final voiceProvider = FlaiProviders.of(context).voiceProvider;
    if (voiceProvider == null) return;

    _voiceController = FlaiVoiceController(
      provider: voiceProvider,
      onError: (message) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    )..addListener(_onVoiceStateChanged);
  }

  void _onVoiceStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _voiceController?.removeListener(_onVoiceStateChanged);
    _voiceController?.dispose();
    super.dispose();
  }

  /// Builds a [SidebarConfig] that merges the consumer's config with the
  /// home screen's overridable callbacks and the settings config.
  SidebarConfig get _effectiveSidebarConfig {
    return SidebarConfig(
      appName: widget.sidebarConfig.appName,
      appLogo: widget.sidebarConfig.appLogo,
      workspaceLabel: widget.sidebarConfig.workspaceLabel ??
          widget.userProfile?.workspaceLabel,
      onWorkspaceTap: widget.sidebarConfig.onWorkspaceTap,
      navItems: widget.sidebarConfig.navItems,
      enableSearch: widget.sidebarConfig.enableSearch,
      topNavActions: widget.sidebarConfig.topNavActions,
      settingsConfig: widget.settingsConfig,
      onNewChat: widget.onNewChat ?? widget.sidebarConfig.onNewChat,
      onConversationTap:
          widget.onConversationTap ?? widget.sidebarConfig.onConversationTap,
      onConversationStar: widget.sidebarConfig.onConversationStar,
      onConversationRename: widget.sidebarConfig.onConversationRename,
      onConversationShare: widget.sidebarConfig.onConversationShare,
      onConversationDelete: widget.sidebarConfig.onConversationDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final effectiveConfig = _effectiveSidebarConfig;
    final hasActiveChat = widget.chatContent != null;
    final vc = _voiceController;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colors.background,
      drawer: FlaiSidebarDrawer(
        config: effectiveConfig,
        userProfile: widget.userProfile,
        starred: widget.starredConversations,
        recents: widget.conversations,
        selectedConversationId: widget.activeConversationId,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FlaiTopNavBar(
              appName: effectiveConfig.appLogo != null
                  ? ''
                  : effectiveConfig.appName,
              logo: effectiveConfig.appLogo,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              actions: effectiveConfig.topNavActions,
            ),
            Expanded(
              child: hasActiveChat
                  ? widget.chatContent!
                  : FlaiEmptyChatState(config: widget.chatExperienceConfig),
            ),
            // Show composer when on the empty "new chat" state.
            // When chatContent is provided, the consumer's widget
            // is expected to include its own composer.
            if (!hasActiveChat) ...[
              if (widget.chatExperienceConfig.suggestionPrompts.isNotEmpty)
                _SuggestionChipsRow(
                  prompts: widget.chatExperienceConfig.suggestionPrompts,
                  onTap: (prompt) =>
                      (widget.onSendMessage ?? (_) {})(prompt.prompt),
                ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    theme.spacing.md,
                    0,
                    theme.spacing.md,
                    theme.spacing.sm,
                  ),
                  child: FlaiComposerV2(
                    config: widget.chatExperienceConfig,
                    onSend: widget.onSendMessage ?? (_) {},
                    currentModeId: _currentModeId,
                    onModeChanged: (mode) {
                      setState(() => _currentModeId = mode.id);
                      widget.onModeChanged?.call(mode);
                    },
                    currentSearchModeId: _currentSearchModeId,
                    onSearchModeChanged: (m) =>
                        setState(() => _currentSearchModeId = m.id),
                    isRecording: vc?.isRecording ?? false,
                    isTranscribing: vc?.isTranscribing ?? false,
                    voiceTranscript: vc?.lastTranscript,
                    onVoiceStart: vc != null ? () => vc.startRecording() : null,
                    onVoiceStop: vc != null ? () => vc.stopRecording() : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontally-scrolling row of suggestion chips rendered above the
/// composer when the chat is empty. Tapping a chip immediately sends
/// its prompt as a new message.
class _SuggestionChipsRow extends StatelessWidget {
  final List<SuggestionPrompt> prompts;
  final ValueChanged<SuggestionPrompt> onTap;

  const _SuggestionChipsRow({required this.prompts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.xs,
        ),
        itemCount: prompts.length,
        separatorBuilder: (_, _) => SizedBox(width: theme.spacing.xs),
        itemBuilder: (_, index) {
          final p = prompts[index];
          return InkWell(
            borderRadius: BorderRadius.circular(theme.radius.full),
            onTap: () => onTap(p),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.sm,
                vertical: theme.spacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colors.muted,
                borderRadius: BorderRadius.circular(theme.radius.full),
                border: Border.all(color: theme.colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.icon != null) ...[
                    Icon(p.icon, size: 14, color: theme.colors.foreground),
                    SizedBox(width: theme.spacing.xs),
                  ],
                  Text(
                    p.displayLabel,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
