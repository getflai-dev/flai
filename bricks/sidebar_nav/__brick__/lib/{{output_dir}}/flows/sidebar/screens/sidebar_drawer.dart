import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../sidebar_config.dart';
import '../widgets/chat_list_item.dart';
import 'settings_drawer.dart';

/// A full-featured sidebar drawer for AI chat apps.
///
/// Linear/Raycast-inspired layout: dense, borders-only, restrained typography.
/// The header combines an optional brand logo, a workspace switcher chip
/// ([SidebarConfig.workspaceLabel] + [SidebarConfig.onWorkspaceTap]), and a
/// "new chat" affordance. Below it sit search, top-level nav, the grouped
/// conversation list, and a sticky user/settings footer.
class FlaiSidebarDrawer extends StatefulWidget {
  /// Top-level sidebar configuration.
  final SidebarConfig config;

  /// The signed-in user's profile, used in the footer and settings sheet.
  final UserProfile? userProfile;

  /// Starred conversations shown in the "Starred" section.
  final List<ConversationItem> starred;

  /// Recent conversations shown in the "Recents" section.
  final List<ConversationItem> recents;

  /// The ID of the currently active conversation, if any.
  final String? selectedConversationId;

  const FlaiSidebarDrawer({
    super.key,
    required this.config,
    this.userProfile,
    this.starred = const [],
    this.recents = const [],
    this.selectedConversationId,
  });

  @override
  State<FlaiSidebarDrawer> createState() => _FlaiSidebarDrawerState();
}

class _FlaiSidebarDrawerState extends State<FlaiSidebarDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ConversationItem> _filtered(List<ConversationItem> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items
        .where(
          (item) =>
              item.title.toLowerCase().contains(q) ||
              item.preview.toLowerCase().contains(q),
        )
        .toList();
  }

  void _openSettings(BuildContext context) {
    if (widget.config.settingsConfig == null) return;
    showSettingsDrawer(
      context: context,
      config: widget.config.settingsConfig!,
      userProfile: widget.userProfile,
    );
  }

  Map<String, List<ConversationItem>> _groupByDate(
    List<ConversationItem> items,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<ConversationItem>>{};
    for (final item in items) {
      final date = DateTime(
        item.timestamp.year,
        item.timestamp.month,
        item.timestamp.day,
      );
      String key;
      if (date == today || date.isAfter(today)) {
        key = 'Today';
      } else if (date == yesterday ||
          (date.isAfter(yesterday) && date.isBefore(today))) {
        key = 'Yesterday';
      } else if (date.isAfter(weekAgo)) {
        key = 'Previous 7 Days';
      } else {
        key = 'Older';
      }
      (groups[key] ??= []).add(item);
    }
    return groups;
  }

  List<Widget> _buildGroupedRecents(
    List<ConversationItem> items,
    FlaiThemeData theme,
  ) {
    final groups = _groupByDate(items);
    const order = ['Today', 'Yesterday', 'Previous 7 Days', 'Older'];
    final widgets = <Widget>[];

    for (final label in order) {
      final group = groups[label];
      if (group == null || group.isEmpty) continue;
      widgets.add(_SectionHeader(label: label, theme: theme));
      for (final item in group) {
        widgets.add(
          ChatListItem(
            item: item,
            isSelected: item.id == widget.selectedConversationId,
            onTap: () => widget.config.onConversationTap?.call(item),
            onStar: () => widget.config.onConversationStar?.call(item),
            onRename: () => widget.config.onConversationRename?.call(item),
            onShare: () => widget.config.onConversationShare?.call(item),
            onDelete: () => widget.config.onConversationDelete?.call(item),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final filteredStarred = _filtered(widget.starred);
    final filteredRecents = _filtered(widget.recents);

    return Drawer(
      backgroundColor: theme.colors.background,
      shape: const RoundedRectangleBorder(),
      elevation: 0,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: brand + workspace + new chat ─────────────────
            _SidebarHeader(
              config: widget.config,
              theme: theme,
            ),

            // ── Search ──────────────────────────────────────────────
            if (widget.config.enableSearch)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.spacing.md,
                  4,
                  theme.spacing.md,
                  theme.spacing.sm,
                ),
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  theme: theme,
                ),
              ),

            // ── Nav items (dense, hover-style rows) ─────────────────
            if (widget.config.navItems.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: theme.spacing.sm),
                child: Column(
                  children: [
                    for (final item in widget.config.navItems)
                      _NavRow(
                        icon: item.icon,
                        label: item.label,
                        onTap: () {
                          if (item.page != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => item.page!,
                              ),
                            );
                          }
                        },
                        theme: theme,
                      ),
                  ],
                ),
              ),
              SizedBox(height: theme.spacing.xs),
              Divider(
                color: theme.colors.border,
                height: 1,
                thickness: 0.5,
              ),
            ],

            // ── Conversations (scrollable) ───────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(top: theme.spacing.xs),
                children: [
                  if (filteredStarred.isNotEmpty) ...[
                    _SectionHeader(label: 'Starred', theme: theme),
                    ...filteredStarred.map(
                      (item) => ChatListItem(
                        item: item,
                        isSelected: item.id == widget.selectedConversationId,
                        onTap: () =>
                            widget.config.onConversationTap?.call(item),
                        onStar: () =>
                            widget.config.onConversationStar?.call(item),
                        onRename: () =>
                            widget.config.onConversationRename?.call(item),
                        onShare: () =>
                            widget.config.onConversationShare?.call(item),
                        onDelete: () =>
                            widget.config.onConversationDelete?.call(item),
                      ),
                    ),
                  ],
                  if (filteredRecents.isNotEmpty)
                    ..._buildGroupedRecents(filteredRecents, theme),
                  if (filteredStarred.isEmpty && filteredRecents.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(theme.spacing.lg),
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No conversations yet'
                            : 'No results for "$_searchQuery"',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            // ── Footer: user profile / settings entry ───────────────
            Divider(color: theme.colors.border, height: 1, thickness: 0.5),
            _UserFooter(
              profile: widget.userProfile,
              hasSettings: widget.config.settingsConfig != null,
              onTap: () => _openSettings(context),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  final SidebarConfig config;
  final FlaiThemeData theme;

  const _SidebarHeader({required this.config, required this.theme});

  @override
  Widget build(BuildContext context) {
    final hasLogo = config.appLogo != null;
    final hasWorkspace = config.workspaceLabel != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.md,
        theme.spacing.sm,
        theme.spacing.sm,
        theme.spacing.sm,
      ),
      child: Row(
        children: [
          if (hasLogo)
            DefaultTextStyle.merge(
              style: TextStyle(color: theme.colors.foreground),
              child: config.appLogo!,
            )
          else ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: theme.colors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            SizedBox(width: theme.spacing.sm),
            Text(
              config.appName,
              style: theme.typography.lg.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
          if (hasWorkspace) ...[
            SizedBox(width: theme.spacing.sm),
            _WorkspaceChip(
              label: config.workspaceLabel!,
              onTap: config.onWorkspaceTap,
              theme: theme,
            ),
          ],
          const Spacer(),
          _IconButton(
            icon: Icons.edit_square,
            tooltip: 'New chat',
            onTap: config.onNewChat,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _WorkspaceChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final FlaiThemeData theme;

  const _WorkspaceChip({
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(theme.radius.sm),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: theme.colors.muted,
          borderRadius: BorderRadius.circular(theme.radius.sm),
          border: Border.all(color: theme.colors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.unfold_more_rounded,
              size: 12,
              color: theme.colors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final FlaiThemeData theme;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(theme.radius.sm),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: theme.colors.foreground),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search
// ─────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final FlaiThemeData theme;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: theme.typography.sm.copyWith(color: theme.colors.foreground),
        cursorColor: theme.colors.foreground,
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: theme.typography.sm.copyWith(
            color: theme.colors.mutedForeground,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.colors.mutedForeground,
            size: 16,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          isDense: true,
          filled: true,
          fillColor: theme.colors.muted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.radius.sm),
            borderSide: BorderSide(color: theme.colors.border, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.radius.sm),
            borderSide: BorderSide(color: theme.colors.border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(theme.radius.sm),
            borderSide: BorderSide(color: theme.colors.foreground, width: 0.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav row
// ─────────────────────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final FlaiThemeData theme;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(theme.radius.sm),
      child: Container(
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: theme.spacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 16, color: theme.colors.foreground),
            SizedBox(width: theme.spacing.sm + 2),
            Text(
              label,
              style: theme.typography.sm.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────────────────

class _UserFooter extends StatelessWidget {
  final UserProfile? profile;
  final bool hasSettings;
  final VoidCallback onTap;
  final FlaiThemeData theme;

  const _UserFooter({
    required this.profile,
    required this.hasSettings,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: hasSettings ? onTap : null,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.sm,
        ),
        child: Row(
          children: [
            _Avatar(profile: profile, theme: theme),
            SizedBox(width: theme.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile?.name ?? 'User',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile?.email != null)
                    Text(
                      profile!.email,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (hasSettings)
              Icon(
                Icons.settings_rounded,
                size: 14,
                color: theme.colors.mutedForeground,
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserProfile? profile;
  final FlaiThemeData theme;

  const _Avatar({required this.profile, required this.theme});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p?.avatarUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          p!.avatarUrl!,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initials(p.initials),
        ),
      );
    }
    return _initials(p?.initials ?? '?');
  }

  Widget _initials(String initials) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: theme.colors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: theme.typography.sm.copyWith(
          color: theme.colors.primaryForeground,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final FlaiThemeData theme;

  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.md,
        theme.spacing.md,
        theme.spacing.md,
        4,
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.typography.sm.copyWith(
          color: theme.colors.mutedForeground,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
