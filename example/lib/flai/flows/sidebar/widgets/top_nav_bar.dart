import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';

/// A top navigation bar with a hamburger menu, app name, and action buttons.
///
/// Typically placed at the top of the main scaffold to provide access to the
/// sidebar drawer and contextual actions.
class FlaiTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  /// The application name displayed next to the menu icon.
  final String appName;

  /// Called when the user taps the hamburger menu icon.
  final VoidCallback? onMenuTap;

  /// Action widgets displayed in the trailing area of the nav bar.
  final List<Widget> actions;

  /// Creates a [FlaiTopNavBar].
  const FlaiTopNavBar({
    super.key,
    required this.appName,
    this.onMenuTap,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.colors.background,
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenuTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.menu_rounded,
                  size: 24,
                  color: theme.colors.foreground,
                ),
              ),
            ),
          ),
          SizedBox(width: theme.spacing.xs),
          Text(
            appName,
            style: theme.typography.lg.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}
