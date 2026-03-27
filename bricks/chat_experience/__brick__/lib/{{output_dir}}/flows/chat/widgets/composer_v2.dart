import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../chat_experience_config.dart';
import 'attachment_menu.dart';
import 'model_selector_sheet.dart';

/// A composer widget with model selection, attachment menu, and voice input.
///
/// Use [FlaiComposerV2] at the bottom of the chat screen to let users type
/// messages, attach files, switch models, and start voice conversations.
///
/// Voice follows the CMMD Sidekick pattern: tap mic → button pulses red →
/// "Listening..." indicator appears → tap stop → transcript populates the
/// text field for review → user sends manually.
class FlaiComposerV2 extends StatefulWidget {
  /// The chat experience configuration.
  final ChatExperienceConfig config;

  /// Called when the user submits a message.
  final ValueChanged<String> onSend;

  /// The currently selected model id.
  final String? currentModelId;

  /// Called when the user picks a new model.
  final ValueChanged<ModelOption>? onModelChanged;

  /// Called when the user taps the mic to start voice recording.
  final VoidCallback? onVoiceStart;

  /// Called when the user taps stop to end voice recording.
  final VoidCallback? onVoiceStop;

  /// Whether the microphone is actively listening.
  final bool isRecording;

  /// Whether recorded audio is being transcribed to text.
  final bool isTranscribing;

  /// Transcribed text from voice input.
  ///
  /// When this changes to a non-null, non-empty value, the text is
  /// populated into the text field for the user to review before sending.
  final String? voiceTranscript;

  /// Creates a [FlaiComposerV2].
  const FlaiComposerV2({
    super.key,
    required this.config,
    required this.onSend,
    this.currentModelId,
    this.onModelChanged,
    this.onVoiceStart,
    this.onVoiceStop,
    this.isRecording = false,
    this.isTranscribing = false,
    this.voiceTranscript,
  });

  @override
  State<FlaiComposerV2> createState() => _FlaiComposerV2State();
}

class _FlaiComposerV2State extends State<FlaiComposerV2> {
  final TextEditingController _textController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
    });
  }

  @override
  void didUpdateWidget(FlaiComposerV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When voice transcript arrives, populate the text field.
    if (widget.voiceTranscript != null &&
        widget.voiceTranscript != oldWidget.voiceTranscript &&
        widget.voiceTranscript!.isNotEmpty) {
      _textController.text = widget.voiceTranscript!;
      setState(() => _hasText = true);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    widget.onSend(text);
  }

  Future<void> _openAttachmentMenu() async {
    await showAttachmentMenu(
      context: context,
      config: widget.config.composerConfig,
    );
  }

  Future<void> _openModelSelector() async {
    final model = await showModelSelector(
      context: context,
      models: widget.config.availableModels,
      currentModelId: widget.currentModelId,
    );
    if (model != null) {
      widget.onModelChanged?.call(model);
    }
  }

  String? get _currentModelName {
    if (widget.currentModelId == null) return null;
    try {
      return widget.config.availableModels
          .firstWhere((m) => m.id == widget.currentModelId)
          .name;
    } catch (_) {
      return null;
    }
  }

  void _handleMicTap() {
    if (widget.isRecording) {
      widget.onVoiceStop?.call();
    } else {
      widget.onVoiceStart?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Listening / Transcribing indicator (above the input capsule)
        if (widget.isRecording)
          Padding(
            padding: EdgeInsets.only(bottom: theme.spacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Listening\u2026',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          )
        else if (widget.isTranscribing)
          Padding(
            padding: EdgeInsets.only(bottom: theme.spacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: theme.colors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Transcribing\u2026',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),

        // Input capsule
        Container(
          decoration: BoxDecoration(
            color: theme.colors.muted,
            borderRadius: BorderRadius.circular(theme.radius.xl),
            border: Border.all(
              color: theme.colors.border,
              width: 0.5,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.sm,
            vertical: theme.spacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text field (always visible)
              TextField(
                controller: _textController,
                maxLines: 5,
                minLines: 1,
                onSubmitted: (_) => _handleSend(),
                textInputAction: TextInputAction.send,
                style: theme.typography.base.copyWith(
                  color: theme.colors.foreground,
                ),
                decoration: InputDecoration(
                  hintText: widget.isRecording
                      ? 'Listening\u2026'
                      : widget.config.resolvedPlaceholder,
                  hintStyle: theme.typography.base.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.xs,
                    vertical: theme.spacing.xs,
                  ),
                ),
              ),
              // Bottom action row
              Row(
                children: [
                  // Attachment button
                  _ComposerIconButton(
                    icon: Icons.add,
                    filled: false,
                    onTap: _openAttachmentMenu,
                  ),
                  // Model chip
                  if (widget.config.availableModels.isNotEmpty) ...[
                    SizedBox(width: theme.spacing.xs),
                    GestureDetector(
                      onTap: _openModelSelector,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: theme.spacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colors.background,
                          borderRadius:
                              BorderRadius.circular(theme.radius.full),
                          border: Border.all(color: theme.colors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentModelName ??
                                  widget.config.availableModels.first.name,
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.foreground,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: theme.spacing.xs),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 14,
                              color: theme.colors.mutedForeground,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Mic or send button
                  if (widget.config.enableVoice && !_hasText)
                    _VoiceMicButton(
                      isListening: widget.isRecording,
                      onTap: _handleMicTap,
                    )
                  else
                    _ComposerIconButton(
                      icon: Icons.arrow_upward,
                      filled: _hasText,
                      onTap: _hasText ? _handleSend : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Animated mic button that pulses red when actively listening.
///
/// Matches the CMMD Sidekick voice input pattern: red background with
/// pulsing shadow when listening, neutral when idle. Tap toggles state.
class _VoiceMicButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const _VoiceMicButton({
    required this.isListening,
    required this.onTap,
  });

  @override
  State<_VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<_VoiceMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const _activeColor = Color(0xFFFF3B30); // iOS system red

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_VoiceMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.isListening
                      ? _activeColor
                      : theme.colors.background,
                  shape: BoxShape.circle,
                  border: widget.isListening
                      ? null
                      : Border.all(color: theme.colors.border),
                  boxShadow: widget.isListening
                      ? [
                          BoxShadow(
                            color: _activeColor.withValues(
                              alpha:
                                  0.3 * (_pulseAnimation.value - 1.0) / 0.3,
                            ),
                            blurRadius: 12 * _pulseAnimation.value,
                            spreadRadius:
                                2 * (_pulseAnimation.value - 1.0),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.isListening ? Icons.stop_rounded : Icons.mic,
                  size: 18,
                  color: widget.isListening
                      ? Colors.white
                      : theme.colors.foreground,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A circular icon button used inside the composer.
///
/// Meets Apple HIG minimum touch target of 44x44pt.
class _ComposerIconButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  const _ComposerIconButton({
    required this.icon,
    required this.filled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    final bgColor =
        filled ? theme.colors.primary : theme.colors.background;
    final fgColor =
        filled ? theme.colors.primaryForeground : theme.colors.foreground;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: filled ? null : Border.all(color: theme.colors.border),
            ),
            child: Icon(icon, size: 18, color: fgColor),
          ),
        ),
      ),
    );
  }
}
