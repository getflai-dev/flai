import 'package:flutter/material.dart';
import '../flai/flai.dart';

class MockInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;

  const MockInputBar({super.key, required this.onSend});

  @override
  State<MockInputBar> createState() => _MockInputBarState();
}

class _MockInputBarState extends State<MockInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      setState(() => _hasText = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.md,
        vertical: theme.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colors.card,
        border: Border(top: BorderSide(color: theme.colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: theme.colors.mutedForeground,
                size: 20,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            SizedBox(width: theme.spacing.xs),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: theme.colors.background,
                  borderRadius: BorderRadius.circular(theme.radius.lg),
                  border: Border.all(color: theme.colors.input),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  onChanged: (t) =>
                      setState(() => _hasText = t.trim().isNotEmpty),
                  onSubmitted: (_) => _send(),
                  style: theme.typography.bodyBase(
                    color: theme.colors.foreground,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message...',
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
            SizedBox(width: theme.spacing.xs),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_upward,
                  color: _hasText
                      ? theme.colors.primaryForeground
                      : theme.colors.mutedForeground,
                  size: 20,
                ),
                onPressed: _hasText ? _send : null,
                style: IconButton.styleFrom(
                  backgroundColor: _hasText
                      ? theme.colors.primary
                      : theme.colors.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(theme.radius.full),
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
