import 'package:flutter/material.dart';
import '../../../core/theme/flai_theme.dart';

/// An animated, selectable pill chip for onboarding multi-select screens.
///
/// Toggles between selected and unselected states with a spring animation.
/// Shows a checkmark icon when selected.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md,
          vertical: theme.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? theme.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(theme.radius.full),
          border: Border.all(
            color: isSelected ? theme.colors.primary : theme.colors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_rounded,
                size: 16,
                color: theme.colors.primaryForeground,
              ),
              SizedBox(width: theme.spacing.xs),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: theme.colors.mutedForeground,
              ),
              SizedBox(width: theme.spacing.xs),
            ],
            Text(
              label,
              style: theme.typography.sm.copyWith(
                color: isSelected
                    ? theme.colors.primaryForeground
                    : theme.colors.foreground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
