import 'package:flutter/material.dart';
import '../flai/flai.dart';

class MockMessageBubble extends StatelessWidget {
  final Message message;

  const MockMessageBubble({super.key, required this.message});

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
        margin: EdgeInsets.only(
          left: isUser ? theme.spacing.xl : theme.spacing.md,
          right: isUser ? theme.spacing.md : theme.spacing.xl,
          bottom: theme.spacing.sm,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (message.hasThinking) ...[
              _ThinkingBlock(content: message.thinkingContent!, theme: theme),
              SizedBox(height: theme.spacing.xs),
            ],
            Container(
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
                  Text(
                    message.content,
                    style: theme.typography.bodyBase(
                      color: isUser
                          ? theme.colors.userBubbleForeground
                          : theme.colors.assistantBubbleForeground,
                    ),
                  ),
                  if (message.hasToolCalls) ...[
                    SizedBox(height: theme.spacing.sm),
                    ...message.toolCalls!.map(
                      (tc) => _ToolCallChip(toolCall: tc, theme: theme),
                    ),
                  ],
                  if (message.hasCitations) ...[
                    SizedBox(height: theme.spacing.sm),
                    ...message.citations!.map(
                      (c) => _CitationChip(citation: c, theme: theme),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: theme.spacing.xs / 2),
              child: Text(
                _formatTime(message.timestamp),
                style: theme.typography.bodySmall(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ThinkingBlock extends StatefulWidget {
  final String content;
  final FlaiThemeData theme;

  const _ThinkingBlock({required this.content, required this.theme});

  @override
  State<_ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<_ThinkingBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: EdgeInsets.all(theme.spacing.sm),
        decoration: BoxDecoration(
          color: theme.colors.muted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(theme.radius.md),
          border: Border.all(color: theme.colors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 14,
                  color: theme.colors.mutedForeground,
                ),
                SizedBox(width: theme.spacing.xs),
                Text(
                  'Thinking...',
                  style: theme.typography.bodySmall(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: theme.colors.mutedForeground,
                ),
              ],
            ),
            if (_expanded) ...[
              SizedBox(height: theme.spacing.xs),
              Text(
                widget.content,
                style: theme.typography.bodySmall(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolCallChip extends StatelessWidget {
  final ToolCall toolCall;
  final FlaiThemeData theme;

  const _ToolCallChip({required this.toolCall, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: theme.spacing.xs),
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.sm,
        vertical: theme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colors.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(theme.radius.sm),
        border: Border.all(color: theme.colors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            toolCall.isComplete ? Icons.check_circle : Icons.hourglass_top,
            size: 12,
            color: toolCall.isComplete
                ? const Color(0xFF4ade80)
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

class _CitationChip extends StatelessWidget {
  final Citation citation;
  final FlaiThemeData theme;

  const _CitationChip({required this.citation, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: theme.spacing.xs),
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.sm,
        vertical: theme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(theme.radius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 12, color: theme.colors.accentForeground),
          SizedBox(width: theme.spacing.xs),
          Flexible(
            child: Text(
              citation.title,
              style: theme.typography.bodySmall(
                color: theme.colors.accentForeground,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
