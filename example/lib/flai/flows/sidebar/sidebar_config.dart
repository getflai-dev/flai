import 'package:flutter/widgets.dart';

import 'settings_config.dart';

/// A navigation item shown in the sidebar drawer.
class NavItem {
  /// The icon for this nav item.
  final IconData icon;

  /// The display label for this nav item.
  final String label;

  /// The page widget this item navigates to, or null if handled by [onTap].
  final Widget? page;

  /// Creates a [NavItem].
  const NavItem({
    required this.icon,
    required this.label,
    this.page,
  });
}

/// Profile information for the signed-in user.
class UserProfile {
  /// The user's display name.
  final String name;

  /// The user's email address.
  final String email;

  /// An optional URL for the user's avatar image.
  final String? avatarUrl;

  /// The user's initials, used as a fallback avatar when [avatarUrl] is null.
  final String initials;

  /// An optional workspace or organization label.
  final String? workspaceLabel;

  /// Creates a [UserProfile].
  const UserProfile({
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.initials,
    this.workspaceLabel,
  });
}

/// A single conversation entry displayed in the chat list.
class ConversationItem {
  /// Unique identifier for this conversation.
  final String id;

  /// The conversation title.
  final String title;

  /// A short preview of the last message.
  final String preview;

  /// When the conversation was last updated.
  final DateTime timestamp;

  /// Whether this conversation has been starred by the user.
  final bool isStarred;

  /// The number of unread messages (0 = none).
  final int unreadCount;

  /// Creates a [ConversationItem].
  const ConversationItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.timestamp,
    this.isStarred = false,
    this.unreadCount = 0,
  });

  /// Returns a copy with the given fields replaced.
  ConversationItem copyWith({
    String? id,
    String? title,
    String? preview,
    DateTime? timestamp,
    bool? isStarred,
    int? unreadCount,
  }) {
    return ConversationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      timestamp: timestamp ?? this.timestamp,
      isStarred: isStarred ?? this.isStarred,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Top-level configuration for the sidebar navigation experience.
class SidebarConfig {
  /// The application name shown in the top nav bar.
  final String appName;

  /// An optional logo widget shown instead of the app name text.
  final Widget? appLogo;

  /// The navigation items shown in the sidebar drawer.
  final List<NavItem> navItems;

  /// Whether to show a search bar in the sidebar.
  final bool enableSearch;

  /// Action widgets displayed in the top nav bar trailing area.
  final List<Widget> topNavActions;

  /// Configuration for the settings sheet.
  final SettingsConfig? settingsConfig;

  /// Called when the user taps the "New Chat" button.
  final VoidCallback? onNewChat;

  /// Called when the user taps a conversation.
  final void Function(ConversationItem)? onConversationTap;

  /// Called when the user stars or unstars a conversation.
  final void Function(ConversationItem)? onConversationStar;

  /// Called when the user renames a conversation.
  final void Function(ConversationItem, String newTitle)? onConversationRename;

  /// Called when the user shares a conversation.
  final void Function(ConversationItem)? onConversationShare;

  /// Called when the user deletes a conversation.
  final void Function(ConversationItem)? onConversationDelete;

  /// Creates a [SidebarConfig].
  const SidebarConfig({
    required this.appName,
    this.appLogo,
    this.navItems = const [],
    this.enableSearch = false,
    this.topNavActions = const [],
    this.settingsConfig,
    this.onNewChat,
    this.onConversationTap,
    this.onConversationStar,
    this.onConversationRename,
    this.onConversationShare,
    this.onConversationDelete,
  });
}
