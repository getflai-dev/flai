import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../chat_experience_config.dart';
import 'attachment_picker.dart';

/// Shows the attachment options bottom sheet.
///
/// The top [AttachSection] renders Camera, Photos, Files as rounded-rectangle
/// cards matching the standard iOS pattern. Items with no [AttachItem.onTap]
/// use the built-in [FlaiAttachmentPicker] to open native device pickers.
///
/// When [searchModes] is non-empty, an additional `Search Mode` segmented
/// control is appended to the sheet. The current selection (persisted by
/// the host, typically per-chat) is reflected via [currentSearchModeId],
/// and changes are reported via [onSearchModeChanged].
Future<void> showAttachmentMenu({
  required BuildContext context,
  required ComposerConfig config,
  ValueChanged<PickedAttachment>? onAttachmentPicked,
  List<SearchModeOption> searchModes = const [],
  String? currentSearchModeId,
  ValueChanged<SearchModeOption>? onSearchModeChanged,
}) {
  final theme = FlaiTheme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: theme.colors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => FlaiTheme(
      data: theme,
      child: _AttachmentMenuSheet(
        config: config,
        onAttachmentPicked: onAttachmentPicked,
        searchModes: searchModes,
        currentSearchModeId: currentSearchModeId,
        onSearchModeChanged: onSearchModeChanged,
      ),
    ),
  );
}

class _AttachmentMenuSheet extends StatefulWidget {
  final ComposerConfig config;
  final ValueChanged<PickedAttachment>? onAttachmentPicked;
  final List<SearchModeOption> searchModes;
  final String? currentSearchModeId;
  final ValueChanged<SearchModeOption>? onSearchModeChanged;

  const _AttachmentMenuSheet({
    required this.config,
    this.onAttachmentPicked,
    this.searchModes = const [],
    this.currentSearchModeId,
    this.onSearchModeChanged,
  });

  @override
  State<_AttachmentMenuSheet> createState() => _AttachmentMenuSheetState();
}

class _AttachmentMenuSheetState extends State<_AttachmentMenuSheet> {
  final Set<int> _selectedChipIndices = {};
  String? _searchModeId;

  @override
  void initState() {
    super.initState();
    _searchModeId =
        widget.currentSearchModeId ??
        (widget.searchModes.isNotEmpty ? widget.searchModes.first.id : null);
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

  /// Resolve the tap action for an [AttachItem].
  ///
  /// If the item has a custom [onTap], use it. Otherwise, use the built-in
  /// device picker based on the item label (Camera, Photos, Files).
  Future<void> _handleAttachTap(AttachItem item) async {
    Navigator.of(context).pop();

    if (item.onTap != null) {
      item.onTap!.call();
      return;
    }

    // Built-in device pickers for standard attachment types.
    PickedAttachment? picked;
    switch (item.label) {
      case 'Camera':
        picked = await FlaiAttachmentPicker.openCamera();
      case 'Photos':
        picked = await FlaiAttachmentPicker.openPhotos();
      case 'Files':
        picked = await FlaiAttachmentPicker.openFiles();
    }
    if (picked != null) {
      widget.onAttachmentPicked?.call(picked);
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
                    color: theme.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Header row with close button and title
            Padding(
              padding: EdgeInsets.fromLTRB(
                theme.spacing.sm,
                theme.spacing.sm,
                theme.spacing.md,
                0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colors.muted,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: theme.colors.foreground,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Add to Chat',
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            ...widget.config.attachmentSections.map(
              (section) => _buildSection(context, theme, section),
            ),
            if (widget.searchModes.isNotEmpty)
              _buildSearchModeSection(context, theme),
            SizedBox(height: theme.spacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchModeSection(BuildContext context, FlaiThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.xs,
          ),
          child: Text(
            'SEARCH MODE',
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: theme.colors.muted,
              borderRadius: BorderRadius.circular(theme.radius.full),
              border: Border.all(color: theme.colors.border),
            ),
            child: Row(
              children: widget.searchModes.map((mode) {
                final isSelected = mode.id == _searchModeId;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _searchModeId = mode.id);
                      widget.onSearchModeChanged?.call(mode);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                        vertical: theme.spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colors.background
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(theme.radius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (mode.icon != null) ...[
                            Icon(
                              mode.icon,
                              size: 14,
                              color: isSelected
                                  ? theme.colors.foreground
                                  : theme.colors.mutedForeground,
                            ),
                            SizedBox(width: theme.spacing.xs),
                          ],
                          Text(
                            mode.name,
                            style: theme.typography.sm.copyWith(
                              color: isSelected
                                  ? theme.colors.foreground
                                  : theme.colors.mutedForeground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: theme.spacing.sm),
      ],
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
        children: section.items.map((item) {
          final index = section.items.indexOf(item);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < section.items.length - 1
                    ? theme.spacing.sm
                    : 0,
              ),
              child: GestureDetector(
                onTap: () => _handleAttachTap(item),
                child: Container(
                  height: 88,
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius: BorderRadius.circular(theme.radius.lg),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 28,
                        color: theme.colors.foreground,
                      ),
                      SizedBox(height: theme.spacing.sm),
                      Text(
                        item.label,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
            onTap: () => _handleAttachTap(item),
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
