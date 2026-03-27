import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_controller.dart';

/// Forgot password confirmation screen.
///
/// Shows the user's email and a Continue button to send the reset email.
class FlaiForgotPassword extends StatelessWidget {
  const FlaiForgotPassword({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final config = controller.config;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: theme.colors.background,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
              child: Column(
                children: [
                  // Header: back + logo + close
                  Padding(
                    padding: EdgeInsets.only(top: theme.spacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: controller.goBack,
                          icon: Icon(
                            Icons.arrow_back,
                            color: theme.colors.foreground,
                          ),
                        ),
                        if (config.appLogo != null)
                          config.appLogo!
                        else
                          const SizedBox(width: 24),
                        IconButton(
                          onPressed: () =>
                              controller.goTo(AuthScreen.loginLanding),
                          icon: Icon(
                            Icons.close,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: theme.spacing.xl),

                  // Heading
                  Text(
                    'Reset password',
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: theme.spacing.sm),

                  // Subtitle with email
                  Text(
                    'Click "Continue" to reset your password for ${controller.email}',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: controller.isLoading
                          ? null
                          : controller.sendResetEmail,
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colors.foreground,
                        foregroundColor: theme.colors.background,
                        disabledBackgroundColor: theme.colors.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            theme.radius.full,
                          ),
                        ),
                      ),
                      child: controller.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colors.background,
                              ),
                            )
                          : Text('Continue', style: theme.typography.base),
                    ),
                  ),

                  if (controller.errorMessage != null) ...[
                    SizedBox(height: theme.spacing.md),
                    Text(
                      controller.errorMessage!,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.destructive,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
