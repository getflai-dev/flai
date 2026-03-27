import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_controller.dart';
import '../widgets/auth_text_field.dart';

/// Verification code entry screen.
///
/// Shared for both sign-up verification and password reset flows.
/// Shows email, code input, resend option, and password fallback.
class FlaiVerificationCode extends StatefulWidget {
  const FlaiVerificationCode({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  State<FlaiVerificationCode> createState() => _FlaiVerificationCodeState();
}

class _FlaiVerificationCodeState extends State<FlaiVerificationCode> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    widget.controller.verifyCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final config = widget.controller.config;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: theme.colors.background,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(top: theme.spacing.md),
                      child: IconButton(
                        onPressed: () => widget.controller.goTo(
                          AuthScreen.loginLanding,
                        ),
                        icon: Icon(
                          Icons.close,
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // Logo
                  if (config.appLogo != null) ...[
                    config.appLogo!,
                    SizedBox(height: theme.spacing.md),
                  ],

                  // Heading
                  Text(
                    'Check your inbox',
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: theme.spacing.sm),

                  Text(
                    'Enter the verification code we just sent to ${widget.controller.email}',
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // Code field
                  AuthTextField(
                    controller: _codeController,
                    hintText: 'Code',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    errorText: widget.controller.errorMessage,
                    onSubmitted: (_) => _submit(),
                  ),

                  SizedBox(height: theme.spacing.md),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: widget.controller.isLoading ? null : _submit,
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colors.foreground,
                        foregroundColor: theme.colors.background,
                        disabledBackgroundColor: theme.colors.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(theme.radius.full),
                        ),
                      ),
                      child: widget.controller.isLoading
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

                  SizedBox(height: theme.spacing.md),

                  // Resend
                  TextButton(
                    onPressed: widget.controller.isLoading
                        ? null
                        : widget.controller.resendCode,
                    child: Text(
                      'Resend email',
                      style: theme.typography.base.copyWith(
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),

                  // OR + password fallback
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: theme.spacing.md),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: theme.colors.border)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: theme.spacing.md,
                          ),
                          child: Text(
                            'OR',
                            style: theme.typography.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: theme.colors.border)),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => widget.controller.goTo(
                        AuthScreen.passwordEntry,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colors.foreground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(theme.radius.full),
                          side: BorderSide(color: theme.colors.border),
                        ),
                      ),
                      child: Text(
                        'Continue with password',
                        style: theme.typography.base,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
