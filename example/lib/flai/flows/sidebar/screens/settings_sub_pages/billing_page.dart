import 'package:flutter/material.dart';

import '../../../../core/theme/flai_theme.dart';

/// A stub billing settings page that developers can customize.
///
/// Shows the current plan, an upgrade prompt, and an upgrade action button.
class FlaiBillingPage extends StatelessWidget {
  /// Called when the user taps the back button.
  final VoidCallback onBack;

  /// Creates a [FlaiBillingPage].
  const FlaiBillingPage({super.key, required this.onBack});

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
                'Billing',
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
                // Current plan card
                Container(
                  padding: EdgeInsets.all(theme.spacing.md),
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius: BorderRadius.circular(theme.radius.md),
                    border: Border.all(color: theme.colors.border, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Plan',
                        style: theme.typography.base.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      Text(
                        'Free',
                        style: theme.typography.base.copyWith(
                          color: theme.colors.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: theme.spacing.md),

                // Upgrade description
                Text(
                  'Upgrade your plan for more features',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                SizedBox(height: theme.spacing.lg),

                // Upgrade button
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colors.foreground,
                    side: BorderSide(color: theme.colors.border, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(theme.radius.md),
                    ),
                    padding: EdgeInsets.symmetric(vertical: theme.spacing.sm),
                  ),
                  child: Text(
                    'Upgrade',
                    style: theme.typography.base.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
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
