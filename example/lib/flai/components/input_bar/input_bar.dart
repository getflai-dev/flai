import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/flai_theme.dart';

/// A production-quality chat input bar with text field, send button,
/// and optional attachment support.
///
/// Styled via [FlaiTheme] tokens. Supports multi-line input with dynamic
/// height growth, Enter-to-send on desktop/web, and SafeArea bottom padding.
class FlaiInputBar extends StatefulWidget {
  /// Called when the user submits a message.
  final ValueChanged<String> onSend;

  /// Called when the attachment button is tapped. If null, the attachment
  /// button is hidden.
  final VoidCallback? onAttachmentTap;

  /// Called whenever the text field content changes.
  final ValueChanged<String>? onTextChanged;

  /// Placeholder hint text displayed when the field is empty.
  final String placeholder;

  /// Whether the input bar is interactive.
  final bool enabled;

  /// Maximum number of visible text lines before the field scrolls.
  final int maxLines;

  /// Whether the text field should autofocus when first built.
  final bool autofocus;

  const FlaiInputBar({
    super.key,
    required this.onSend,
    this.onAttachmentTap,
    this.onTextChanged,
    this.placeholder = 'Message...',
    this.enabled = true,
    this.maxLines = 5,
    this.autofocus = false,
  });

  @override
  State<FlaiInputBar> createState() => _FlaiInputBarState();
}

class _FlaiInputBarState extends State<FlaiInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
    _focusNode.requestFocus();
  }

  void _onChanged(String value) {
    final hasText = value.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onTextChanged?.call(value);
  }

  /// Handles keyboard submit on desktop / web (Enter without Shift).
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isEnter = event.logicalKey == LogicalKeyboardKey.enter;
    final isShiftHeld = HardwareKeyboard.instance.isShiftPressed;

    if (isEnter && !isShiftHeld) {
      _send();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.card,
        border: Border(top: BorderSide(color: theme.colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button
              if (widget.onAttachmentTap != null)
                Padding(
                  padding: EdgeInsets.only(right: theme.spacing.xs),
                  child: IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: widget.enabled
                          ? theme.colors.mutedForeground
                          : theme.colors.muted,
                      size: 20,
                    ),
                    onPressed: widget.enabled ? widget.onAttachmentTap : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),

              // Text field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colors.background,
                    borderRadius: BorderRadius.circular(theme.radius.lg),
                    border: Border.all(color: theme.colors.input),
                  ),
                  child: Focus(
                    onKeyEvent: _handleKeyEvent,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      autofocus: widget.autofocus,
                      maxLines: widget.maxLines,
                      minLines: 1,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.newline,
                      style: theme.typography.bodyBase(
                        color: theme.colors.foreground,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.placeholder,
                        hintStyle: theme.typography.bodyBase(
                          color: theme.colors.mutedForeground,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: theme.spacing.md,
                          vertical: theme.spacing.sm,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Send button
              Padding(
                padding: EdgeInsets.only(left: theme.spacing.xs),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_upward,
                      color: _hasText && widget.enabled
                          ? theme.colors.primaryForeground
                          : theme.colors.mutedForeground,
                      size: 20,
                    ),
                    onPressed: _hasText && widget.enabled ? _send : null,
                    style: IconButton.styleFrom(
                      backgroundColor: _hasText && widget.enabled
                          ? theme.colors.primary
                          : theme.colors.muted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme.radius.full),
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
