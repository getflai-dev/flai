import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';

/// A compact workspace/organization switcher widget.
///
/// Displays the current workspace label with an expand icon. Tapping it
/// triggers [onTap], which should present a workspace picker.
class WorkspaceSwitcher extends StatelessWidget {
  /// The current workspace label. Defaults to "Personal" when null.
  final String? workspaceLabel;

  /// Called when the user taps the switcher.
  final VoidCallback? onTap;

  /// Creates a [WorkspaceSwitcher].
  const WorkspaceSwitcher({super.key, this.workspaceLabel, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colors.border, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              workspaceLabel ?? 'Personal',
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            SizedBox(width: theme.spacing.xs),
            Icon(
              Icons.unfold_more_rounded,
              size: 16,
              color: theme.colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
