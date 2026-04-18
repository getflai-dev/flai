import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../settings_config.dart';
import '../sidebar_config.dart';
import '../widgets/settings_row_widget.dart';
import '../widgets/workspace_switcher.dart';

/// Pushes the full-screen settings page.
///
/// Replaces the previous bottom-sheet implementation to match the CMMD web
/// architecture: settings is a route with a back button, and sub-pages are
/// pushed onto the standard [Navigator] stack via [NavigationRow.onTap].
///
/// ```dart
/// NavigationRow(
///   label: 'Profile',
///   onTap: () => Navigator.of(context).push(
///     MaterialPageRoute(builder: (_) => const FlaiProfilePage()),
///   ),
/// )
/// ```
void showSettingsDrawer({
  required BuildContext context,
  required SettingsConfig config,
  UserProfile? userProfile,
}) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => FlaiSettingsScreen(
        config: config,
        userProfile: userProfile,
      ),
      fullscreenDialog: true,
    ),
  );
}

/// Full-screen settings page.
///
/// Renders the user header, optional workspace switcher, and the configured
/// [SettingsSection] list. Each [NavigationRow] is responsible for its own
/// `onTap` (typically pushes another [MaterialPageRoute]).
class FlaiSettingsScreen extends StatelessWidget {
  final SettingsConfig config;
  final UserProfile? userProfile;

  const FlaiSettingsScreen({
    super.key,
    required this.config,
    this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        backgroundColor: theme.colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: theme.colors.foreground,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Settings',
          style: theme.typography.lg.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colors.foreground,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: theme.spacing.xl),
        children: [
          if (userProfile != null) _UserHeader(profile: userProfile!),
          if (config.showWorkspaceSwitcher)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.md,
                vertical: theme.spacing.xs,
              ),
              child: WorkspaceSwitcher(
                workspaceLabel: userProfile?.workspaceLabel,
              ),
            ),
          Divider(color: theme.colors.border, height: 1),
          for (final section in config.sections) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                theme.spacing.md,
                theme.spacing.md,
                theme.spacing.md,
                theme.spacing.xs,
              ),
              child: Text(
                section.title.toUpperCase(),
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            for (final row in section.rows)
              SettingsRowWidget(
                row: row,
                onNavigate: row is NavigationRow
                    ? () {
                        if (row.onTap != null) row.onTap!();
                      }
                    : null,
              ),
            Divider(color: theme.colors.border, height: 1),
          ],
          if (config.infoItems.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(theme.spacing.md),
              child: Wrap(
                spacing: theme.spacing.md,
                runSpacing: theme.spacing.xs,
                children: config.infoItems
                    .map(
                      (item) => GestureDetector(
                        onTap: item.onTap,
                        child: Text(
                          item.label,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          if (config.appVersion != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
              child: Text(
                'v${config.appVersion}',
                style: theme.typography.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  final UserProfile profile;

  const _UserHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.md,
        vertical: theme.spacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: profile.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      profile.avatarUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    profile.initials,
                    style: theme.typography.base.copyWith(
                      color: theme.colors.primaryForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          SizedBox(width: theme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.name,
                  style: theme.typography.lg.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  profile.email,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                if (profile.workspaceLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.workspaceLabel!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
