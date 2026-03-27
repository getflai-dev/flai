import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/message_bubble/message_bubble.dart';
import '../components/typing_indicator/typing_indicator.dart';
import '../core/models/message.dart';
import '../core/theme/flai_theme.dart';
import '../flows/chat/chat_experience_config.dart';
import '../flows/chat/voice_controller.dart';
import '../flows/chat/widgets/composer_v2.dart';
import '../providers.dart';

/// The active chat content area: message list + composer.
///
/// Uses the real FlAI component bricks (MessageBubble, FlaiTypingIndicator)
/// instead of hand-rolled widgets.
class FlaiChatContent extends StatefulWidget {
  final List<Message> messages;
  final ChatExperienceConfig config;
  final ValueChanged<String> onSend;
  final bool isStreaming;
  final void Function(Message)? onRetry;
  final void Function(Message)? onRegenerate;

  const FlaiChatContent({
    super.key,
    required this.messages,
    required this.config,
    required this.onSend,
    this.isStreaming = false,
    this.onRetry,
    this.onRegenerate,
  });

  @override
  State<FlaiChatContent> createState() => _FlaiChatContentState();
}

class _FlaiChatContentState extends State<FlaiChatContent> {
  final ScrollController _scrollController = ScrollController();
  FlaiVoiceController? _voiceController;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final distanceFromBottom = pos.maxScrollExtent - pos.pixels;
    final shouldShow = distanceFromBottom > 200;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

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
    _voiceController =
        FlaiVoiceController(
          provider: vp,
          onError: (msg) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(msg)));
            }
          },
        )..addListener(() {
          if (mounted) setState(() {});
        });
  }

  @override
  void didUpdateWidget(FlaiChatContent old) {
    super.didUpdateWidget(old);
    // Scroll to bottom when new messages arrive or content changes.
    if (widget.messages.length != old.messages.length ||
        (widget.messages.isNotEmpty &&
            old.messages.isNotEmpty &&
            widget.messages.last.content != old.messages.last.content)) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _voiceController?.dispose();
    super.dispose();
  }

  /// Finds the previous user message before the given index.
  Message? _findPreviousUserMessage(int assistantIndex) {
    for (var i = assistantIndex - 1; i >= 0; i--) {
      if (widget.messages[i].role == MessageRole.user) {
        return widget.messages[i];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final vc = _voiceController;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: theme.spacing.md,
                  vertical: theme.spacing.sm,
                ),
                itemCount:
                    widget.messages.length +
                    (widget.isStreaming && _isWaitingForFirstToken ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show typing indicator as the last item while waiting for first token.
                  if (index == widget.messages.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: FlaiTypingIndicator(),
                      ),
                    );
                  }

                  final msg = widget.messages[index];

                  // Skip rendering the empty streaming placeholder — the typing
                  // indicator above handles that state.
                  if (msg.isStreaming && msg.content.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Assistant messages: avatar + bubble + optional regenerate button
                  if (msg.role == MessageRole.assistant && !msg.isStreaming) {
                    final previousUser = _findPreviousUserMessage(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(top: 4, right: 8),
                                decoration: BoxDecoration(
                                  color: theme.colors.muted,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                              Expanded(
                                child: MessageBubble(
                                  message: msg,
                                  onRetry: widget.onRetry,
                                ),
                              ),
                            ],
                          ),
                          // Regenerate button for completed assistant messages
                          if (msg.status == MessageStatus.complete &&
                              previousUser != null &&
                              widget.onRegenerate != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 32, top: 2),
                              child: GestureDetector(
                                onTap: () => widget.onRegenerate!(previousUser),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                      color: theme.colors.mutedForeground,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Regenerate',
                                      style: theme.typography.bodySmall(
                                        color: theme.colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: MessageBubble(message: msg, onRetry: widget.onRetry),
                  );
                },
              ),
              // Scroll-to-bottom FAB
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showScrollToBottom ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_showScrollToBottom,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _scrollToBottom();
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.colors.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: theme.colors.foreground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

  /// True when streaming is active but no text has arrived yet.
  bool get _isWaitingForFirstToken {
    if (!widget.isStreaming) return false;
    if (widget.messages.isEmpty) return true;
    final last = widget.messages.last;
    return last.isStreaming && last.content.isEmpty;
  }
}
