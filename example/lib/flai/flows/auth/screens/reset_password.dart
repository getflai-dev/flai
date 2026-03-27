import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_controller.dart';
import '../widgets/auth_text_field.dart';

/// Reset password screen — set a new password after code verification.
class FlaiResetPassword extends StatefulWidget {
  const FlaiResetPassword({super.key, required this.controller});

  final AuthController controller;

  @override
  State<FlaiResetPassword> createState() => _FlaiResetPasswordState();
}

class _FlaiResetPasswordState extends State<FlaiResetPassword> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _localError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty) {
      setState(() => _localError = 'Password is required');
      return;
    }
    if (password != confirm) {
      setState(() => _localError = 'Passwords do not match');
      return;
    }
    setState(() => _localError = null);
    widget.controller.resetPassword(password);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final config = widget.controller.config;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final error = _localError ?? widget.controller.errorMessage;

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
                          onPressed: widget.controller.goBack,
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
                              widget.controller.goTo(AuthScreen.loginLanding),
                          icon: Icon(
                            Icons.close,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: theme.spacing.lg),

                  Text(
                    'Set new password',
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // New password
                  AuthTextField(
                    controller: _passwordController,
                    hintText: 'New password',
                    obscureText: _obscurePassword,
                    autofocus: true,
                    suffix: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: theme.colors.mutedForeground,
                        size: 20,
                      ),
                    ),
                  ),

                  SizedBox(height: theme.spacing.md),

                  // Confirm password
                  AuthTextField(
                    controller: _confirmController,
                    hintText: 'Confirm password',
                    obscureText: _obscureConfirm,
                    errorText: error,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    suffix: IconButton(
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: theme.colors.mutedForeground,
                        size: 20,
                      ),
                    ),
                  ),

                  SizedBox(height: theme.spacing.md),

                  // Submit button
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
                          borderRadius: BorderRadius.circular(
                            theme.radius.full,
                          ),
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
                          : Text(
                              'Reset password',
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
