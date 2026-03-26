import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../settings_config.dart';
import '../sidebar_config.dart';
import '../widgets/settings_row_widget.dart';
import '../widgets/workspace_switcher.dart';

/// Opens the settings bottom sheet for the given [config] and [userProfile].
///
/// The sheet supports navigating into sub-pages via [NavigationRow] taps.
/// Developers configure sub-pages by setting [NavigationRow.onTap] to a
/// callback that calls the provided [pushPage] function:
///
/// ```dart
/// NavigationRow(
///   label: 'Profile',
///   onTap: () => pushPage(const FlaiProfilePage(onBack: popPage)),
/// )
/// ```
///
/// The sheet closes when the user drags it down or taps outside.
void showSettingsDrawer({
  required BuildContext context,
  required SettingsConfig config,
  UserProfile? userProfile,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SettingsDrawerSheet(
      config: config,
      userProfile: userProfile,
    ),
  );
}

class _SettingsDrawerSheet extends StatefulWidget {
  final SettingsConfig config;
  final UserProfile? userProfile;

  const _SettingsDrawerSheet({
    required this.config,
    required this.userProfile,
  });

  @override
  State<_SettingsDrawerSheet> createState() => _SettingsDrawerSheetState();
}

class _SettingsDrawerSheetState extends State<_SettingsDrawerSheet> {
  /// Stack of sub-pages pushed on top of the root settings view.
  final List<Widget> _pageStack = [];

  void _pushPage(Widget page) => setState(() => _pageStack.add(page));

  void _popPage() {
    if (_pageStack.isNotEmpty) {
      setState(() => _pageStack.removeLast());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final ratio = widget.config.drawerHeightRatio.clamp(0.4, 1.0);

    return DraggableScrollableSheet(
      initialChildSize: ratio,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
            child: _pageStack.isEmpty
                ? _RootSettingsPage(
                    key: const ValueKey('root'),
                    config: widget.config,
                    userProfile: widget.userProfile,
                    scrollController: scrollController,
                    pushPage: _pushPage,
                    popPage: _popPage,
                    theme: theme,
                  )
                : KeyedSubtree(
                    key: ValueKey(_pageStack.length),
                    child: _pageStack.last,
                  ),
          ),
        );
      },
    );
  }
}

class _RootSettingsPage extends StatelessWidget {
  final SettingsConfig config;
  final UserProfile? userProfile;
  final ScrollController scrollController;
  final void Function(Widget) pushPage;
  final VoidCallback popPage;
  final dynamic theme;

  const _RootSettingsPage({
    super.key,
    required this.config,
    required this.userProfile,
    required this.scrollController,
    required this.pushPage,
    required this.popPage,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: theme.spacing.sm),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colors.mutedForeground.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // User header
        if (userProfile != null)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.md,
              vertical: theme.spacing.sm,
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: userProfile!.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            userProfile!.avatarUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          userProfile!.initials,
                          style: theme.typography.base.copyWith(
                            color: theme.colors.primaryForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                SizedBox(width: theme.spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userProfile!.name,
                        style: theme.typography.base.copyWith(
                          color: theme.colors.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        userProfile!.email,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Workspace switcher
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

        // Sections
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.only(bottom: theme.spacing.xl),
            children: [
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
                            if (row.onTap != null) {
                              row.onTap!();
                            }
                          }
                        : null,
                  ),
                Divider(color: theme.colors.border, height: 1),
              ],

              // Info items (e.g. Privacy Policy, Terms of Service)
              if (config.infoItems.isNotEmpty) ...[
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
              ],

              // App version
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
        ),
      ],
    );
  }
}
