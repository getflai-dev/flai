import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../chat_experience_config.dart';

/// Shows a modal bottom sheet for selecting a [ChatMode].
///
/// Mirrors the CMMD web "Autopilot" picker: each mode is a row with an
/// accent-tinted icon, name, subtitle, and a check mark on the active
/// mode. Returns the selected [ChatMode], or `null` if dismissed.
Future<ChatMode?> showModePicker({
  required BuildContext context,
  required List<ChatMode> modes,
  String? currentModeId,
}) {
  final theme = FlaiTheme.of(context);
  return showModalBottomSheet<ChatMode>(
    context: context,
    backgroundColor: theme.colors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => FlaiTheme(
      data: theme,
      child: _ModePickerSheet(modes: modes, currentModeId: currentModeId),
    ),
  );
}

class _ModePickerSheet extends StatelessWidget {
  final List<ChatMode> modes;
  final String? currentModeId;

  const _ModePickerSheet({required this.modes, this.currentModeId});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: theme.spacing.sm),
            child: Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              theme.spacing.md,
              theme.spacing.md,
              theme.spacing.md,
              theme.spacing.xs,
            ),
            child: Row(
              children: [
                Text(
                  'Mode',
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colors.foreground,
                  ),
                ),
              ],
            ),
          ),
          ...modes.map((mode) {
            final isSelected = mode.id == currentModeId;
            final accent = mode.accent ?? theme.colors.primary;
            return InkWell(
              onTap: () => Navigator.of(context).pop(mode),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: theme.spacing.md,
                  vertical: theme.spacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(theme.radius.md),
                      ),
                      child: Icon(mode.icon, size: 20, color: accent),
                    ),
                    SizedBox(width: theme.spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.name,
                            style: theme.typography.base.copyWith(
                              color: theme.colors.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (mode.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              mode.subtitle!,
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: theme.colors.primary,
                      ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: theme.spacing.sm),
        ],
      ),
    );
  }
}
