import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../sidebar_config.dart';

/// Bottom sheet that lists every workspace the user can switch into and
/// returns the selected workspace id.
///
/// Uses Linear/Raycast-style dense rows: a small monogram tile, the
/// workspace name and role on the left, and a checkmark on the active row.
Future<String?> showWorkspacePickerSheet({
  required BuildContext context,
  required List<WorkspaceOrg> workspaces,
  required String? activeId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _WorkspacePickerSheet(
      workspaces: workspaces,
      activeId: activeId,
    ),
  );
}

class _WorkspacePickerSheet extends StatelessWidget {
  final List<WorkspaceOrg> workspaces;
  final String? activeId;

  const _WorkspacePickerSheet({
    required this.workspaces,
    required this.activeId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        margin: EdgeInsets.all(theme.spacing.sm),
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(theme.radius.md),
          border: Border.all(color: theme.colors.border, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                theme.spacing.md,
                theme.spacing.md,
                theme.spacing.sm,
                theme.spacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Switch workspace',
                      style: theme.typography.base.copyWith(
                        color: theme.colors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: theme.colors.mutedForeground,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(color: theme.colors.border, height: 1, thickness: 0.5),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
                itemCount: workspaces.length,
                itemBuilder: (_, i) {
                  final w = workspaces[i];
                  return _WorkspaceRow(
                    workspace: w,
                    isActive: w.id == activeId,
                    theme: theme,
                    onTap: () => Navigator.of(context).pop(w.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceRow extends StatelessWidget {
  final WorkspaceOrg workspace;
  final bool isActive;
  final FlaiThemeData theme;
  final VoidCallback onTap;

  const _WorkspaceRow({
    required this.workspace,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  String get _initials {
    final name = workspace.name.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.colors.muted,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.colors.border, width: 0.5),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: theme.typography.sm.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
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
                    workspace.name,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (workspace.role != null && workspace.role!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        workspace.role!,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isActive)
              Icon(
                Icons.check_rounded,
                size: 16,
                color: theme.colors.foreground,
              ),
          ],
        ),
      ),
    );
  }
}
