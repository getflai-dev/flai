import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';

/// Themed text field for auth forms with label, error state, and suffix.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? theme.colors.destructive : theme.colors.border,
            ),
            borderRadius: BorderRadius.circular(theme.radius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null)
                Padding(
                  padding: EdgeInsets.only(
                    left: theme.spacing.md,
                    top: theme.spacing.sm,
                  ),
                  child: Text(
                    label!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ),
              TextField(
                controller: controller,
                obscureText: obscureText,
                readOnly: readOnly,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                autofocus: autofocus,
                onSubmitted: onSubmitted,
                style: theme.typography.base.copyWith(
                  color: theme.colors.foreground,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: theme.typography.base.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: theme.spacing.md,
                    vertical: label != null
                        ? theme.spacing.xs
                        : theme.spacing.sm,
                  ),
                  suffixIcon: suffix,
                  isDense: label != null,
                ),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(
              top: theme.spacing.xs,
              left: theme.spacing.sm,
            ),
            child: Text(
              errorText!,
              style: theme.typography.sm.copyWith(
                color: theme.colors.destructive,
              ),
            ),
          ),
      ],
    );
  }
}
