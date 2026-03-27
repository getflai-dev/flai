import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../sidebar_config.dart';
import '../widgets/chat_list_item.dart';
import 'settings_drawer.dart';

/// A full-featured sidebar drawer for AI chat apps.
///
/// Displays the app header, optional conversation search, nav items,
/// starred and recent conversations, and a sticky user profile footer.
/// Tapping the user profile opens the settings sheet.
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

  /// Creates a [FlaiSidebarDrawer].
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

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final filteredStarred = _filtered(widget.starred);
    final filteredRecents = _filtered(widget.recents);

    return Drawer(
      backgroundColor: theme.colors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.md,
                vertical: theme.spacing.sm,
              ),
              child: Row(
                children: [
                  // App logo or default gradient circle
                  if (widget.config.appLogo != null)
                    widget.config.appLogo!
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colors.primary,
                            theme.colors.primary.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  SizedBox(width: theme.spacing.sm),
                  Expanded(
                    child: Text(
                      widget.config.appName,
                      style: theme.typography.lg.copyWith(
                        color: theme.colors.foreground,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // New chat button
                  IconButton(
                    onPressed: widget.config.onNewChat,
                    icon: Icon(
                      Icons.edit_square,
                      color: theme.colors.foreground,
                      size: 22,
                    ),
                    tooltip: 'New chat',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Search ──────────────────────────────────────────────
            if (widget.config.enableSearch)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: theme.spacing.md,
                  vertical: theme.spacing.xs,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: theme.typography.base.copyWith(
                    color: theme.colors.foreground,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search conversations',
                    hintStyle: theme.typography.base.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.colors.mutedForeground,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: theme.colors.muted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme.radius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: theme.spacing.sm,
                    ),
                  ),
                ),
              ),

            // ── Nav items ───────────────────────────────────────────
            if (widget.config.navItems.isNotEmpty)
              ...widget.config.navItems.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.md,
                  ),
                  leading: Icon(
                    item.icon,
                    color: theme.colors.foreground,
                    size: 20,
                  ),
                  title: Text(
                    item.label,
                    style: theme.typography.base.copyWith(
                      color: theme.colors.foreground,
                    ),
                  ),
                  onTap: () {
                    if (item.page != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => item.page!,
                        ),
                      );
                    }
                  },
                  dense: true,
                ),
              ),

            Divider(color: theme.colors.border, height: 1),

            // ── Conversations (scrollable) ───────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Starred section
                  if (filteredStarred.isNotEmpty) ...[
                    _SectionHeader(
                      label: 'Starred',
                      theme: theme,
                    ),
                    ...filteredStarred.map(
                      (item) => ChatListItem(
                        item: item,
                        isSelected: item.id == widget.selectedConversationId,
                        onTap: () => widget.config.onConversationTap?.call(item),
                        onStar: () =>
                            widget.config.onConversationStar?.call(item),
                        onRename: (title) =>
                            widget.config.onConversationRename?.call(
                          item,
                          title,
                        ),
                        onShare: () =>
                            widget.config.onConversationShare?.call(item),
                        onDelete: () =>
                            widget.config.onConversationDelete?.call(item),
                      ),
                    ),
                  ],

                  // Recents section
                  if (filteredRecents.isNotEmpty) ...[
                    _SectionHeader(
                      label: 'Recents',
                      theme: theme,
                    ),
                    ...filteredRecents.map(
                      (item) => ChatListItem(
                        item: item,
                        isSelected: item.id == widget.selectedConversationId,
                        onTap: () => widget.config.onConversationTap?.call(item),
                        onStar: () =>
                            widget.config.onConversationStar?.call(item),
                        onRename: (title) =>
                            widget.config.onConversationRename?.call(
                          item,
                          title,
                        ),
                        onShare: () =>
                            widget.config.onConversationShare?.call(item),
                        onDelete: () =>
                            widget.config.onConversationDelete?.call(item),
                      ),
                    ),
                  ],

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

            // ── Sticky user profile footer ───────────────────────────
            Divider(color: theme.colors.border, height: 1),
            GestureDetector(
                onTap: () => _openSettings(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.md,
                    vertical: theme.spacing.md,
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      _buildAvatar(theme),
                      SizedBox(width: theme.spacing.sm),
                      // Name + workspace
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.userProfile?.name ?? 'User',
                              style: theme.typography.base.copyWith(
                                color: theme.colors.foreground,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.userProfile?.workspaceLabel != null)
                              Text(
                                widget.userProfile!.workspaceLabel!,
                                style: theme.typography.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      // Settings cog hint
                      if (widget.config.settingsConfig != null)
                        Icon(
                          Icons.settings_rounded,
                          size: 18,
                          color: theme.colors.mutedForeground,
                        ),
                    ],
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(dynamic theme) {
    final profile = widget.userProfile;
    if (profile?.avatarUrl != null) {
      return ClipOval(
        child: Image.network(
          profile!.avatarUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initialsAvatar(theme, profile.initials),
        ),
      );
    }
    return _initialsAvatar(theme, profile?.initials ?? '?');
  }

  Widget _initialsAvatar(dynamic theme, String initials) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.colors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: theme.typography.sm.copyWith(
          color: theme.colors.primaryForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A small all-caps section label with muted foreground colour.
class _SectionHeader extends StatelessWidget {
  final String label;
  final dynamic theme;

  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.md,
        theme.spacing.md,
        theme.spacing.md,
        theme.spacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.typography.sm.copyWith(
          color: theme.colors.mutedForeground,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
