import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';

/// A full-width banner displayed when ghost mode (temporary chat) is active.
///
/// Ghost mode indicates the conversation will not be saved.
class GhostModeBanner extends StatelessWidget {
  /// Creates a [GhostModeBanner].
  const GhostModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colors.accent.withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: 0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.xs,
        horizontal: theme.spacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility_off, size: 14, color: theme.colors.accent),
          SizedBox(width: theme.spacing.xs),
          Text(
            'Temporary Chat \u2014 not saved',
            style: theme.typography.sm.copyWith(
              color: theme.colors.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
