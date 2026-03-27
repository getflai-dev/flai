import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../core/models/message.dart';
import '../../core/theme/flai_theme.dart';

/// A chat message bubble that renders user, assistant, system, and tool messages
/// with distinct styling, thinking blocks, tool call chips, citation cards,
/// streaming cursors, and error retry actions.
class MessageBubble extends StatelessWidget {
  /// The message to display.
  final Message message;

  /// Called when a citation is tapped.
  final void Function(Citation citation)? onTapCitation;

  /// Called when the retry button is tapped on an error-status message.
  final void Function(Message message)? onRetry;

  /// Called when the bubble is long-pressed.
  final void Function(Message message)? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.onTapCitation,
    this.onRetry,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return switch (message.role) {
      MessageRole.system => _SystemLayout(
          message: message,
          theme: theme,
          onLongPress: onLongPress,
        ),
      MessageRole.tool => _ToolLayout(
          message: message,
          theme: theme,
          onLongPress: onLongPress,
        ),
      _ => _ChatLayout(
          message: message,
          theme: theme,
          onTapCitation: onTapCitation,
          onRetry: onRetry,
          onLongPress: onLongPress,
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Chat layout (user & assistant)
// ---------------------------------------------------------------------------

class _ChatLayout extends StatelessWidget {
  final Message message;
  final FlaiThemeData theme;
  final void Function(Citation)? onTapCitation;
  final void Function(Message)? onRetry;
  final void Function(Message)? onLongPress;

  const _ChatLayout({
    required this.message,
    required this.theme,
    this.onTapCitation,
    this.onRetry,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    final isError = message.status == MessageStatus.error;

    return Semantics(
      label: isError ? 'error_message_bubble' : null,
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: isUser ? theme.spacing.xl : theme.spacing.md,
            right: isUser ? theme.spacing.md : theme.spacing.xl,
            bottom: theme.spacing.sm,
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Thinking block
              if (message.hasThinking) ...[
                _ThinkingBlock(
                  content: message.thinkingContent!,
                  theme: theme,
                ),
                SizedBox(height: theme.spacing.xs),
              ],

              // Tool call chips (shown above the bubble for assistant messages)
              if (!isUser && message.hasToolCalls) ...[
                _ToolCallChips(
                  toolCalls: message.toolCalls!,
                  theme: theme,
                ),
                SizedBox(height: theme.spacing.xs),
              ],

              // Main bubble
              GestureDetector(
                onLongPress: onLongPress != null
                    ? () => onLongPress!(message)
                    : () {
                        Clipboard.setData(
                          ClipboardData(text: message.content),
                        );
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.md,
                    vertical: theme.spacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colors.userBubble
                        : theme.colors.assistantBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(theme.radius.lg),
                      topRight: Radius.circular(theme.radius.lg),
                      bottomLeft: Radius.circular(
                        isUser ? theme.radius.lg : theme.radius.sm,
                      ),
                      bottomRight: Radius.circular(
                        isUser ? theme.radius.sm : theme.radius.lg,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message content with optional streaming cursor
                      _MessageContent(
                        content: message.content,
                        isStreaming: message.isStreaming,
                        style: theme.typography.bodyBase(
                          color: isUser
                              ? theme.colors.userBubbleForeground
                              : theme.colors.assistantBubbleForeground,
                        ),
                        cursorColor: isUser
                            ? theme.colors.userBubbleForeground
                            : theme.colors.assistantBubbleForeground,
                      ),

                      // Citations
                      if (message.hasCitations) ...[
                        SizedBox(height: theme.spacing.sm),
                        ...message.citations!.map(
                          (c) => _CitationCard(
                            citation: c,
                            theme: theme,
                            onTap: onTapCitation != null
                                ? () => onTapCitation!(c)
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Error state with retry
              if (message.status == MessageStatus.error &&
                  onRetry != null) ...[
                SizedBox(height: theme.spacing.xs),
                _RetryButton(
                  theme: theme,
                  onTap: () => onRetry!(message),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }
}

// ---------------------------------------------------------------------------
// System message layout
// ---------------------------------------------------------------------------

class _SystemLayout extends StatelessWidget {
  final Message message;
  final FlaiThemeData theme;
  final void Function(Message)? onLongPress;

  const _SystemLayout({
    required this.message,
    required this.theme,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onLongPress:
            onLongPress != null ? () => onLongPress!(message) : null,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: theme.spacing.lg,
            vertical: theme.spacing.xs,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colors.muted.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(theme.radius.md),
            border: Border.all(
              color: theme.colors.border.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: theme.typography.bodySmall(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tool message layout
// ---------------------------------------------------------------------------

class _ToolLayout extends StatelessWidget {
  final Message message;
  final FlaiThemeData theme;
  final void Function(Message)? onLongPress;

  const _ToolLayout({
    required this.message,
    required this.theme,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onLongPress:
            onLongPress != null ? () => onLongPress!(message) : null,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: EdgeInsets.only(
            left: theme.spacing.md,
            right: theme.spacing.xl,
            bottom: theme.spacing.sm,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colors.muted.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(theme.radius.md),
            border: Border.all(
              color: theme.colors.border.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.build_rounded,
                size: 14,
                color: theme.colors.mutedForeground,
              ),
              SizedBox(width: theme.spacing.sm),
              Flexible(
                child: Text(
                  message.content,
                  style: theme.typography.bodySmall(
                    color: theme.colors.mutedForeground,
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

// ---------------------------------------------------------------------------
// Thinking block (collapsible)
// ---------------------------------------------------------------------------

class _ThinkingBlock extends StatefulWidget {
  final String content;
  final FlaiThemeData theme;

  const _ThinkingBlock({required this.content, required this.theme});

  @override
  State<_ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<_ThinkingBlock>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: EdgeInsets.all(theme.spacing.sm),
        decoration: BoxDecoration(
          color: theme.colors.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(theme.radius.md),
          border: Border.all(
            color: theme.colors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_rounded,
                  size: 14,
                  color: theme.colors.mutedForeground,
                ),
                SizedBox(width: theme.spacing.xs),
                Text(
                  'Thinking',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const Spacer(),
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Icon(
                    Icons.expand_more,
                    size: 16,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: Padding(
                padding: EdgeInsets.only(top: theme.spacing.xs),
                child: Text(
                  widget.content,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tool call chips
// ---------------------------------------------------------------------------

class _ToolCallChips extends StatelessWidget {
  final List<ToolCall> toolCalls;
  final FlaiThemeData theme;

  const _ToolCallChips({required this.toolCalls, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: theme.spacing.xs,
      runSpacing: theme.spacing.xs,
      children: toolCalls.map((tc) => _ToolCallChip(toolCall: tc, theme: theme)).toList(),
    );
  }
}

class _ToolCallChip extends StatelessWidget {
  final ToolCall toolCall;
  final FlaiThemeData theme;

  const _ToolCallChip({required this.toolCall, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isComplete = toolCall.isComplete;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.sm,
        vertical: theme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(theme.radius.sm),
        border: Border.all(
          color: theme.colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.hourglass_top,
            size: 12,
            color: isComplete
                ? const Color(0xFF4ADE80)
                : theme.colors.mutedForeground,
          ),
          SizedBox(width: theme.spacing.xs),
          Text(
            toolCall.name,
            style: theme.typography.mono(
              color: theme.colors.assistantBubbleForeground,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Citation card
// ---------------------------------------------------------------------------

class _CitationCard extends StatelessWidget {
  final Citation citation;
  final FlaiThemeData theme;
  final VoidCallback? onTap;

  const _CitationCard({
    required this.citation,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.xs),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.sm,
            vertical: theme.spacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: theme.colors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(theme.radius.sm),
            border: Border.all(
              color: theme.colors.accent.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link_rounded,
                size: 13,
                color: theme.colors.accent,
              ),
              SizedBox(width: theme.spacing.xs),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      citation.title,
                      style: theme.typography.bodySmall(
                        color: theme.colors.accentForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (citation.snippet != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        citation.snippet!,
                        style: theme.typography.bodySmall(
                          color: theme.colors.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message content with streaming cursor
// ---------------------------------------------------------------------------

class _MessageContent extends StatelessWidget {
  final String content;
  final bool isStreaming;
  final TextStyle style;
  final Color cursorColor;

  const _MessageContent({
    required this.content,
    required this.isStreaming,
    required this.style,
    required this.cursorColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isStreaming) {
      return MarkdownBody(
        data: content,
        styleSheet: MarkdownStyleSheet(
          p: style,
          listBullet: style,
          code: style.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.transparent,
          ),
          codeblockDecoration: BoxDecoration(
            color: style.color?.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          codeblockPadding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
        ),
        builders: {
          'code': _CodeBlockBuilder(codeColor: style.color),
        },
        selectable: true,
        shrinkWrap: true,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(child: Text(content, style: style)),
        const SizedBox(width: 2),
        _BlinkingCursor(color: cursorColor),
      ],
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final Color color;

  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 2,
        height: 16,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Retry button
// ---------------------------------------------------------------------------

class _RetryButton extends StatelessWidget {
  final FlaiThemeData theme;
  final VoidCallback onTap;

  const _RetryButton({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.sm,
          vertical: theme.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colors.destructive.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(theme.radius.sm),
          border: Border.all(
            color: theme.colors.destructive.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              size: 14,
              color: theme.colors.destructive,
            ),
            SizedBox(width: theme.spacing.xs),
            Text(
              'Retry',
              style: theme.typography.bodySmall(
                color: theme.colors.destructive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Code Block Builder ─────────────────────────────────────────────────

class _CodeBlockBuilder extends MarkdownElementBuilder {
  final Color? codeColor;

  _CodeBlockBuilder({this.codeColor});

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if (element.tag != 'code') return null;
    final parent = element.attributes['class'];
    final lang = parent != null && parent.startsWith('language-')
        ? parent.substring(9)
        : null;
    final code = element.textContent.trimRight();
    return _CodeBlockWidget(code: code, language: lang, codeColor: codeColor);
  }
}

class _CodeBlockWidget extends StatelessWidget {
  final String code;
  final String? language;
  final Color? codeColor;

  const _CodeBlockWidget({
    required this.code,
    this.language,
    this.codeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: codeColor?.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: codeColor?.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                if (language != null)
                  Text(
                    language!,
                    style: TextStyle(
                      fontSize: 11,
                      color: codeColor?.withValues(alpha: 0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 13, color: codeColor?.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text('Copy', style: TextStyle(fontSize: 11, color: codeColor?.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: codeColor),
            ),
          ),
        ],
      ),
    );
  }
}

