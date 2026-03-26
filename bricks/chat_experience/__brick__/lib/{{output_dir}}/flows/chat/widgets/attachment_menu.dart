import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../chat_experience_config.dart';

/// Shows the attachment options bottom sheet.
///
/// Renders sections from [ComposerConfig.attachmentSections].
Future<void> showAttachmentMenu({
  required BuildContext context,
  required ComposerConfig config,
}) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _AttachmentMenuSheet(config: config),
  );
}

class _AttachmentMenuSheet extends StatefulWidget {
  final ComposerConfig config;

  const _AttachmentMenuSheet({required this.config});

  @override
  State<_AttachmentMenuSheet> createState() => _AttachmentMenuSheetState();
}

class _AttachmentMenuSheetState extends State<_AttachmentMenuSheet> {
  final Set<int> _selectedChipIndices = {};

  @override
  void initState() {
    super.initState();
    // Pre-select default chips
    for (final section in widget.config.attachmentSections) {
      if (section is ChipsSection) {
        for (var i = 0; i < section.items.length; i++) {
          if (section.items[i].isDefault) {
            _selectedChipIndices.add(i);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Padding(
              padding: EdgeInsets.only(top: theme.spacing.sm),
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            SizedBox(height: theme.spacing.sm),
            ...widget.config.attachmentSections.map(
              (section) => _buildSection(context, theme, section),
            ),
            SizedBox(height: theme.spacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    FlaiThemeData theme,
    AttachmentSection section,
  ) {
    return switch (section) {
      AttachSection() => _buildAttachSection(context, theme, section),
      CustomSection() => _buildCustomSection(context, theme, section),
      ChipsSection() => _buildChipsSection(context, theme, section),
    };
  }

  Widget _buildAttachSection(
    BuildContext context,
    FlaiThemeData theme,
    AttachSection section,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.md,
        vertical: theme.spacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: section.items
            .map(
              (item) => Padding(
                padding: EdgeInsets.only(right: theme.spacing.md),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    item.onTap?.call();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colors.muted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: theme.colors.foreground,
                        ),
                      ),
                      SizedBox(height: theme.spacing.xs),
                      Text(
                        item.label,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCustomSection(
    BuildContext context,
    FlaiThemeData theme,
    CustomSection section,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.xs,
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
        ...section.items.map(
          (item) => ListTile(
            leading: Icon(item.icon, color: theme.colors.foreground),
            title: Text(
              item.label,
              style: theme.typography.base.copyWith(
                color: theme.colors.foreground,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colors.mutedForeground,
            ),
            onTap: () {
              Navigator.of(context).pop();
              item.onTap?.call();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChipsSection(
    BuildContext context,
    FlaiThemeData theme,
    ChipsSection section,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.xs,
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
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
            itemCount: section.items.length,
            itemBuilder: (_, index) {
              final chip = section.items[index];
              final isSelected = _selectedChipIndices.contains(index);
              return Padding(
                padding: EdgeInsets.only(right: theme.spacing.xs),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedChipIndices.clear();
                        _selectedChipIndices.add(index);
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: theme.spacing.sm,
                        vertical: theme.spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colors.primary
                            : theme.colors.muted,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? theme.colors.primary
                              : theme.colors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (chip.icon != null) ...[
                            Icon(
                              chip.icon,
                              size: 14,
                              color: isSelected
                                  ? theme.colors.primaryForeground
                                  : theme.colors.foreground,
                            ),
                            SizedBox(width: theme.spacing.xs),
                          ],
                          Text(
                            chip.label,
                            style: theme.typography.sm.copyWith(
                              color: isSelected
                                  ? theme.colors.primaryForeground
                                  : theme.colors.foreground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: theme.spacing.sm),
      ],
    );
  }
}
