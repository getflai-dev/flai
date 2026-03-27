import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_controller.dart';
import '../widgets/auth_text_field.dart';

/// Password entry screen for both login and sign up flows.
///
/// In sign up mode, the heading reads "Create a password".
/// In login mode, the heading reads "Enter your password".
class FlaiPasswordEntry extends StatefulWidget {
  const FlaiPasswordEntry({super.key, required this.controller});

  final AuthController controller;

  @override
  State<FlaiPasswordEntry> createState() => _FlaiPasswordEntryState();
}

class _FlaiPasswordEntryState extends State<FlaiPasswordEntry> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    if (widget.controller.isSignUpMode) {
      widget.controller.signUp(password);
    } else {
      widget.controller.signInWithEmail(password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final config = widget.controller.config;
    final isSignUp = widget.controller.isSignUpMode;

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

                  // Heading
                  Text(
                    isSignUp ? 'Create a password' : 'Enter your password',
                    style: theme.typography.lg.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: theme.spacing.lg),

                  // Email (read-only)
                  AuthTextField(
                    controller: TextEditingController(
                      text: widget.controller.email,
                    ),
                    label: 'Email',
                    readOnly: true,
                  ),

                  SizedBox(height: theme.spacing.md),

                  // Password
                  AuthTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: _obscurePassword,
                    autofocus: true,
                    errorText: widget.controller.errorMessage,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
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
                          : Text('Continue', style: theme.typography.base),
                    ),
                  ),

                  // Forgot password (login mode only)
                  if (!isSignUp) ...[
                    SizedBox(height: theme.spacing.md),
                    TextButton(
                      onPressed: () =>
                          widget.controller.goTo(AuthScreen.forgotPassword),
                      child: Text(
                        'Forgot password?',
                        style: theme.typography.base.copyWith(
                          color: theme.colors.foreground,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Terms + Privacy
                  if (config.termsUrl != null || config.privacyUrl != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: theme.spacing.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (config.termsUrl != null)
                            Text(
                              'Terms of Use',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          if (config.termsUrl != null &&
                              config.privacyUrl != null)
                            Text(
                              ' · ',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          if (config.privacyUrl != null)
                            Text(
                              'Privacy Policy',
                              style: theme.typography.sm.copyWith(
                                color: theme.colors.mutedForeground,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                        ],
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
