import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../settings_config.dart';

/// Renders a single [SettingsRow] using sealed-class pattern matching.
///
/// Supports [NavigationRow], [DropdownRow], [ToggleRow], [InfoRow], and
/// [CustomRow] variants. All rows use [FlaiTheme] for consistent styling.
class SettingsRowWidget extends StatelessWidget {
  /// The settings row to render.
  final SettingsRow row;

  /// Called when the user taps a [NavigationRow].
  final VoidCallback? onNavigate;

  /// Creates a [SettingsRowWidget].
  const SettingsRowWidget({
    super.key,
    required this.row,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return switch (row) {
      NavigationRow(:final icon, :final label, :final onTap) =>
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
          leading: icon != null
              ? Icon(icon, color: theme.colors.foreground, size: 20)
              : null,
          title: Text(
            label,
            style: theme.typography.base.copyWith(
              color: theme.colors.foreground,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: theme.colors.mutedForeground,
            size: 20,
          ),
          onTap: onTap ?? onNavigate,
        ),
      DropdownRow(:final icon, :final label, :final value, :final items, :final onChanged) =>
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.xs,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: theme.colors.foreground, size: 20),
                SizedBox(width: theme.spacing.sm),
              ],
              Text(
                label,
                style: theme.typography.base.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
              const Spacer(),
              DropdownButton(
                value: value,
                items: items,
                onChanged: onChanged,
                underline: const SizedBox.shrink(),
                style: theme.typography.base.copyWith(
                  color: theme.colors.foreground,
                ),
                dropdownColor: theme.colors.popover,
                icon: Icon(
                  Icons.unfold_more_rounded,
                  color: theme.colors.mutedForeground,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ToggleRow(:final icon, :final label, :final value, :final onChanged) =>
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.xs,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: theme.colors.foreground, size: 20),
                SizedBox(width: theme.spacing.sm),
              ],
              Text(
                label,
                style: theme.typography.base.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: theme.colors.primary,
              ),
            ],
          ),
        ),
      InfoRow(:final icon, :final label, :final value) =>
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: theme.colors.foreground, size: 20),
                SizedBox(width: theme.spacing.sm),
              ],
              Text(
                label,
                style: theme.typography.base.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: theme.typography.base.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      CustomRow(:final builder) => builder(context),
    };
  }
}
