import 'package:flutter/material.dart';

import '../core/models/message.dart';
import '../core/theme/flai_theme.dart';
import '../flows/chat/chat_experience_config.dart';
import '../flows/chat/voice_controller.dart';
import '../flows/chat/widgets/composer_v2.dart';
import '../providers.dart';

/// The active chat content area: message list + composer.
///
/// Displayed as [FlaiHomeScreen.chatContent] when a conversation is active.
class FlaiChatContent extends StatefulWidget {
  final List<Message> messages;
  final ChatExperienceConfig config;
  final ValueChanged<String> onSend;
  final bool isStreaming;

  const FlaiChatContent({
    super.key,
    required this.messages,
    required this.config,
    required this.onSend,
    this.isStreaming = false,
  });

  @override
  State<FlaiChatContent> createState() => _FlaiChatContentState();
}

class _FlaiChatContentState extends State<FlaiChatContent> {
  final ScrollController _scrollController = ScrollController();
  FlaiVoiceController? _voiceController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initVoice();
  }

  void _initVoice() {
    if (_voiceController != null) return;
    if (!widget.config.enableVoice) return;
    final vp = FlaiProviders.of(context).voiceProvider;
    if (vp == null) return;
    _voiceController = FlaiVoiceController(
      provider: vp,
      onError: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void didUpdateWidget(FlaiChatContent old) {
    super.didUpdateWidget(old);
    if (widget.messages.length > old.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _voiceController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final vc = _voiceController;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.md,
              vertical: theme.spacing.sm,
            ),
            itemCount: widget.messages.length,
            itemBuilder: (context, index) {
              final msg = widget.messages[index];
              return _MessageTile(message: msg);
            },
          ),
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
              config: widget.config,
              onSend: widget.onSend,
              isRecording: vc?.isRecording ?? false,
              isTranscribing: vc?.isTranscribing ?? false,
              voiceTranscript: vc?.lastTranscript,
              onVoiceStart: vc != null ? () => vc.startRecording() : null,
              onVoiceStop: vc != null ? () => vc.stopRecording() : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// A single message row in the chat list.
class _MessageTile extends StatelessWidget {
  final Message message;
  const _MessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: EdgeInsets.only(bottom: theme.spacing.sm),
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colors.primary
              : theme.colors.card,
          borderRadius: BorderRadius.circular(theme.radius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.hasThinking)
              Padding(
                padding: EdgeInsets.only(bottom: theme.spacing.xs),
                child: Text(
                  message.thinkingContent!,
                  style: theme.typography.bodySmall(
                    color: (isUser
                            ? theme.colors.primaryForeground
                            : theme.colors.mutedForeground)
                        .withValues(alpha: 0.7),
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            Text(
              message.content.isNotEmpty
                  ? message.content
                  : (message.isStreaming ? '...' : ''),
              style: theme.typography.bodyBase(
                color: isUser
                    ? theme.colors.primaryForeground
                    : theme.colors.foreground,
              ),
            ),
            if (message.status == MessageStatus.error)
              Padding(
                padding: EdgeInsets.only(top: theme.spacing.xs),
                child: Text(
                  'Failed to send',
                  style: theme.typography.bodySmall(
                    color: theme.colors.destructive,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
