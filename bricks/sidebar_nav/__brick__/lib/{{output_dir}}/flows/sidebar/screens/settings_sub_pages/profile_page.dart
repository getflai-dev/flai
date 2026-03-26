import 'package:flutter/material.dart';

import '../../../../core/theme/flai_theme.dart';

/// A stub profile settings page that developers can customize.
///
/// Shows fields for name, nickname, and personal preferences, plus
/// update and delete account actions.
class FlaiProfilePage extends StatelessWidget {
  /// Called when the user taps the back button.
  final VoidCallback onBack;

  /// Creates a [FlaiProfilePage].
  const FlaiProfilePage({super.key, required this.onBack});

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
                'Profile',
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
                // Name field
                Text(
                  'Name',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: theme.typography.base.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    filled: true,
                    fillColor: theme.colors.muted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme.radius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: theme.spacing.md,
                      vertical: theme.spacing.sm,
                    ),
                  ),
                  style: theme.typography.base.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
                SizedBox(height: theme.spacing.md),

                // Nickname field
                Text(
                  'Nickname',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'What should the AI call you?',
                    hintStyle: theme.typography.base.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    filled: true,
                    fillColor: theme.colors.muted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme.radius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: theme.spacing.md,
                      vertical: theme.spacing.sm,
                    ),
                  ),
                  style: theme.typography.base.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
                SizedBox(height: theme.spacing.md),

                // Personal preferences field
                Text(
                  'Personal preferences',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        'Tell the AI about yourself, your goals, or preferences…',
                    hintStyle: theme.typography.base.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    filled: true,
                    fillColor: theme.colors.muted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme.radius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.all(theme.spacing.md),
                    alignLabelWithHint: true,
                  ),
                  style: theme.typography.base.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
                SizedBox(height: theme.spacing.lg),

                // Update button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colors.primary,
                      foregroundColor: theme.colors.primaryForeground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme.radius.md),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Update',
                      style: theme.typography.base.copyWith(
                        color: theme.colors.primaryForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: theme.spacing.xl),

                // Delete account
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Delete account',
                      style: theme.typography.base.copyWith(
                        color: theme.colors.destructive,
                      ),
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
