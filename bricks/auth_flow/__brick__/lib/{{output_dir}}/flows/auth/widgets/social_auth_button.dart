import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_flow_config.dart';

/// Styled button for social authentication (Apple, Google, Microsoft, Phone).
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.type,
    required this.onTap,
    this.isLoading = false,
  });

  final SocialAuthType type;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final (label, icon, isPrimary) = switch (type) {
      SocialAuthType.apple => ('Continue with Apple', Icons.apple, true),
      SocialAuthType.google => ('Continue with Google', Icons.g_mobiledata, false),
      SocialAuthType.microsoft => ('Continue with Microsoft', Icons.window, false),
      SocialAuthType.phone => ('Continue with phone', Icons.phone, false),
    };

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: isLoading ? null : onTap,
        style: TextButton.styleFrom(
          backgroundColor: isPrimary ? theme.colors.foreground : Colors.transparent,
          foregroundColor: isPrimary ? theme.colors.background : theme.colors.foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radius.full),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: theme.colors.border),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isPrimary ? theme.colors.background : theme.colors.foreground,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: theme.typography.base),
                ],
              ),
      ),
    );
  }
}
