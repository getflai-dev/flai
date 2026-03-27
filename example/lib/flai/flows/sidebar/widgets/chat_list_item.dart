import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/flai_theme.dart';
import '../sidebar_config.dart';

/// A list tile representing a single conversation in the chat history.
///
/// Supports swipe-to-star (right) and swipe-to-delete (left) via [Dismissible],
/// plus a long-press context menu with Star, Rename, Share, and Delete actions.
class ChatListItem extends StatelessWidget {
  /// The conversation data to display.
  final ConversationItem item;

  /// Whether this conversation is currently selected/active.
  final bool isSelected;

  /// Called when the user taps this item.
  final VoidCallback? onTap;

  /// Called when the user stars or unstars this conversation.
  final VoidCallback? onStar;

  /// Called when the user requests to rename this conversation.
  /// The parent is responsible for showing the rename dialog.
  final VoidCallback? onRename;

  /// Called when the user shares this conversation.
  final VoidCallback? onShare;

  /// Called when the user deletes this conversation.
  final VoidCallback? onDelete;

  /// Creates a [ChatListItem].
  const ChatListItem({
    super.key,
    required this.item,
    this.isSelected = false,
    this.onTap,
    this.onStar,
    this.onRename,
    this.onShare,
    this.onDelete,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inDays == 0) {
      final hour = timestamp.hour.toString().padLeft(2, '0');
      final minute = timestamp.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year % 100}';
    }
  }

  void _showContextMenu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  item.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                ),
                title: Text(item.isStarred ? 'Unstar' : 'Star'),
                onTap: () => Navigator.of(ctx).pop('star'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Rename'),
                onTap: () => Navigator.of(ctx).pop('rename'),
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share'),
                onTap: () => Navigator.of(ctx).pop('share'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.of(ctx).pop('delete'),
              ),
            ],
          ),
        );
      },
    );
    // Handle action AFTER bottom sheet is fully dismissed
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'star':
        onStar?.call();
      case 'rename':
        // Close the drawer BEFORE signaling rename intent.
        // The parent shows the rename dialog from outside the drawer.
        Scaffold.of(context).closeDrawer();
        onRename?.call();
      case 'share':
        onShare?.call();
      case 'delete':
        onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Dismissible(
      key: ValueKey(item.id),
      // Swipe right → star/unstar (keep in list)
      background: Container(
        color: Colors.amber,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: theme.spacing.lg),
        child: const Icon(Icons.star_rounded, color: Colors.white),
      ),
      // Swipe left → delete (remove from list)
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: theme.spacing.lg),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact();
          onStar?.call();
          return false; // keep in list
        } else {
          HapticFeedback.mediumImpact();
          onDelete?.call();
          return true; // remove from list
        }
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: isSelected
              ? theme.colors.muted
              : Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colors.muted,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'AI',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: theme.spacing.sm),
              // Title and preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (item.isStarred) ...[
                          Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: Colors.amber,
                          ),
                          SizedBox(width: theme.spacing.xs),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.typography.base.copyWith(
                              color: theme.colors.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      item.preview,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: theme.spacing.sm),
              // Timestamp and unread badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTimestamp(item.timestamp),
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  if (item.unreadCount > 0) ...[
                    SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.primaryForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
