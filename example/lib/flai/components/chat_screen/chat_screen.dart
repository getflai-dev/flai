import 'package:flutter/material.dart';

import '../../core/models/message.dart';
import '../../core/theme/flai_theme.dart';
import '../message_bubble/message_bubble.dart';
import '../input_bar/input_bar.dart';
import '../typing_indicator/typing_indicator.dart';
import 'chat_screen_controller.dart';

/// A full-page AI chat screen that composes [MessageBubble], [FlaiInputBar],
/// and [FlaiTypingIndicator] into a complete chat experience.
///
/// Connects to a [ChatScreenController] for state management and AI provider
/// interaction.
///
/// ```dart
/// final controller = ChatScreenController(provider: myAiProvider);
///
/// FlaiChatScreen(
///   controller: controller,
///   title: 'AI Assistant',
///   subtitle: 'Claude 3.5 Sonnet',
/// )
/// ```
class FlaiChatScreen extends StatefulWidget {
  /// Controller managing chat state and AI interaction.
  final ChatScreenController controller;

  /// Title displayed in the header.
  final String? title;

  /// Subtitle displayed below the title (e.g., model name).
  final String? subtitle;

  /// Optional leading widget in the header (e.g., avatar).
  final Widget? leading;

  /// Optional trailing widgets in the header (e.g., settings button).
  final List<Widget>? actions;

  /// Called when a citation is tapped in a message.
  final void Function(Citation citation)? onTapCitation;

  /// Called when a message is long-pressed.
  final void Function(Message message)? onLongPress;

  /// Called when the attachment button is tapped.
  final VoidCallback? onAttachmentTap;

  /// Whether to show the header bar.
  final bool showHeader;

  /// Placeholder text for the input field.
  final String inputPlaceholder;

  /// Widget to display when there are no messages.
  final Widget? emptyState;

  const FlaiChatScreen({
    super.key,
    required this.controller,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.onTapCitation,
    this.onLongPress,
    this.onAttachmentTap,
    this.showHeader = true,
    this.inputPlaceholder = 'Message...',
    this.emptyState,
  });

  @override
  State<FlaiChatScreen> createState() => _FlaiChatScreenState();
}

class _FlaiChatScreenState extends State<FlaiChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(FlaiChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(String text) {
    widget.controller.sendMessage(text);
  }

  void _handleRetry(Message message) {
    widget.controller.retry();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final controller = widget.controller;
    final messages = controller.messages;

    return Column(
      children: [
        // Header
        if (widget.showHeader) _buildHeader(theme),

        // Messages
        Expanded(
          child: messages.isEmpty && !controller.isStreaming
              ? _buildEmptyState(theme)
              : _buildMessageList(theme, controller),
        ),

        // Input bar
        FlaiInputBar(
          onSend: _handleSend,
          onAttachmentTap: widget.onAttachmentTap,
          placeholder: widget.inputPlaceholder,
          enabled: !controller.isStreaming,
        ),
      ],
    );
  }

  Widget _buildHeader(FlaiThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + theme.spacing.sm,
        left: theme.spacing.md,
        right: theme.spacing.md,
        bottom: theme.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colors.card,
        border: Border(bottom: BorderSide(color: theme.colors.border)),
      ),
      child: Row(
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            SizedBox(width: theme.spacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: theme.typography.bodyBase(
                      color: theme.colors.foreground,
                    ),
                  ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: theme.typography.bodySmall(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.actions != null) ...widget.actions!,
        ],
      ),
    );
  }

  Widget _buildEmptyState(FlaiThemeData theme) {
    if (widget.emptyState != null) return widget.emptyState!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: theme.colors.mutedForeground.withValues(alpha: 0.4),
          ),
          SizedBox(height: theme.spacing.md),
          Text(
            'Start a conversation',
            style: theme.typography.bodyLarge(
              color: theme.colors.mutedForeground,
            ),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            'Send a message to begin',
            style: theme.typography.bodySmall(
              color: theme.colors.mutedForeground.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    FlaiThemeData theme,
    ChatScreenController controller,
  ) {
    final messages = controller.messages;
    final itemCount =
        messages.length +
        (controller.isStreaming ? 1 : 0) + // streaming message
        (controller.isStreaming && controller.streamingText.isEmpty
            ? 1
            : 0); // typing indicator

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: theme.spacing.md),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Completed messages
        if (index < messages.length) {
          return MessageBubble(
            message: messages[index],
            onTapCitation: widget.onTapCitation,
            onRetry: _handleRetry,
            onLongPress: widget.onLongPress,
          );
        }

        // Typing indicator (when streaming but no text yet)
        if (controller.isStreaming &&
            controller.streamingText.isEmpty &&
            index == messages.length) {
          return const FlaiTypingIndicator();
        }

        // Streaming message (partial response)
        if (controller.isStreaming && controller.streamingText.isNotEmpty) {
          return MessageBubble(
            message: Message(
              id: 'streaming',
              role: MessageRole.assistant,
              content: controller.streamingText,
              timestamp: DateTime.now(),
              status: MessageStatus.streaming,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
