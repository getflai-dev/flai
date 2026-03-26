import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../chat_experience_config.dart';
import 'attachment_menu.dart';
import 'model_selector_sheet.dart';
import 'voice_recorder.dart';

/// A composer widget with model selection, attachment menu, and voice input.
///
/// Use [FlaiComposerV2] at the bottom of the chat screen to let users type
/// messages, attach files, switch models, and start voice conversations.
class FlaiComposerV2 extends StatefulWidget {
  /// The chat experience configuration.
  final ChatExperienceConfig config;

  /// Called when the user submits a message.
  final ValueChanged<String> onSend;

  /// The currently selected model id.
  final String? currentModelId;

  /// Called when the user picks a new model.
  final ValueChanged<ModelOption>? onModelChanged;

  /// Called when the user starts voice recording.
  final VoidCallback? onVoiceStart;

  /// Called when the user stops voice recording.
  final VoidCallback? onVoiceStop;

  /// Whether the composer is in active recording mode.
  final bool isRecording;

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

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Container(
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
          // Input or voice recorder
          if (widget.isRecording)
            VoiceRecorder(
              onStop: widget.onVoiceStop,
              onCancel: widget.onVoiceStop,
            )
          else
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
                hintText: widget.config.resolvedPlaceholder,
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
              if (widget.config.enableVoice &&
                  !_hasText &&
                  !widget.isRecording)
                _ComposerIconButton(
                  icon: Icons.mic,
                  filled: false,
                  onTap: widget.onVoiceStart,
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
    );
  }
}

/// A small circular icon button used inside the composer.
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
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: theme.colors.border),
        ),
        child: Icon(icon, size: 16, color: fgColor),
      ),
    );
  }
}
