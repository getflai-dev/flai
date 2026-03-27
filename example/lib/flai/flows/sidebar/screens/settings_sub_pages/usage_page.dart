import 'package:flutter/material.dart';

import '../../../../core/theme/flai_theme.dart';

/// A stub usage statistics page that developers can customize.
///
/// Displays session message count and a weekly limit progress indicator.
class FlaiUsagePage extends StatelessWidget {
  /// Called when the user taps the back button.
  final VoidCallback onBack;

  /// Creates a [FlaiUsagePage].
  const FlaiUsagePage({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: theme.colors.foreground,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: theme.spacing.sm),
              Text(
                'Usage',
                style: theme.typography.lg.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(theme.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // This session card
                Container(
                  padding: EdgeInsets.all(theme.spacing.md),
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius: BorderRadius.circular(theme.radius.md),
                    border: Border.all(color: theme.colors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Session',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: theme.spacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Messages',
                            style: theme.typography.base.copyWith(
                              color: theme.colors.foreground,
                            ),
                          ),
                          Text(
                            '0',
                            style: theme.typography.base.copyWith(
                              color: theme.colors.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: theme.spacing.lg),

                // Weekly limit section
                Text(
                  'Weekly Limit',
                  style: theme.typography.base.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: theme.spacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.0,
                    minHeight: 8,
                    backgroundColor: theme.colors.muted,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colors.primary,
                    ),
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  '0 / 100 messages',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Text(
                  'Resets in 7 days',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
