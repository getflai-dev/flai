import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../flai/flai.dart';

class MockCodeBlock extends StatelessWidget {
  final String code;
  final String language;

  const MockCodeBlock({super.key, required this.code, this.language = 'dart'});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: theme.spacing.sm),
      decoration: BoxDecoration(
        color: theme.colors.muted,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(color: theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.sm,
              vertical: theme.spacing.xs,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.colors.border)),
            ),
            child: Row(
              children: [
                Text(
                  language,
                  style: theme.typography.bodySmall(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied!'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: theme.colors.primary,
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy,
                        size: 12,
                        color: theme.colors.mutedForeground,
                      ),
                      SizedBox(width: theme.spacing.xs / 2),
                      Text(
                        'Copy',
                        style: theme.typography.bodySmall(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(theme.spacing.sm),
            child: Text(
              code,
              style: theme.typography.mono(
                color: theme.colors.foreground,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
