import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../chat_experience_config.dart';

/// Shows a modal bottom sheet for selecting an AI model.
///
/// Returns the selected [ModelOption], or `null` if dismissed.
Future<ModelOption?> showModelSelector({
  required BuildContext context,
  required List<ModelOption> models,
  String? currentModelId,
}) {
  return showModalBottomSheet<ModelOption>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _ModelSelectorSheet(
      models: models,
      currentModelId: currentModelId,
    ),
  );
}

class _ModelSelectorSheet extends StatelessWidget {
  final List<ModelOption> models;
  final String? currentModelId;

  const _ModelSelectorSheet({
    required this.models,
    this.currentModelId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          // Heading
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: theme.spacing.md,
              horizontal: theme.spacing.md,
            ),
            child: Text(
              'Select Model',
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colors.foreground,
              ),
            ),
          ),
          // Model list
          ...models.map((model) {
            final isSelected = model.id == currentModelId;
            return ListTile(
              leading: model.icon != null
                  ? Icon(model.icon, color: theme.colors.foreground)
                  : null,
              title: Text(
                model.name,
                style: theme.typography.base.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: theme.colors.foreground,
                ),
              ),
              subtitle: model.description != null
                  ? Text(
                      model.description!,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    )
                  : null,
              trailing: isSelected
                  ? Icon(Icons.check, color: theme.colors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(model),
            );
          }),
          SizedBox(height: theme.spacing.sm),
        ],
      ),
    );
  }
}
