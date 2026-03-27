import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/social_auth_button.dart';

/// Email entry screen for login or sign up.
class FlaiEmailEntry extends StatefulWidget {
  const FlaiEmailEntry({super.key, required this.controller});

  final AuthController controller;

  @override
  State<FlaiEmailEntry> createState() => _FlaiEmailEntryState();
}

class _FlaiEmailEntryState extends State<FlaiEmailEntry> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    widget.controller.submitEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final config = widget.controller.config;

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
          child: Column(
            children: [
              // Header with close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(top: theme.spacing.md),
                  child: IconButton(
                    onPressed: () =>
                        widget.controller.goTo(AuthScreen.loginLanding),
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
                config.emailHeading,
                style: theme.typography.lg.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (config.emailSubtitle != null) ...[
                SizedBox(height: theme.spacing.xs),
                Text(
                  config.emailSubtitle!,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              SizedBox(height: theme.spacing.lg),

              // Email field
              AuthTextField(
                controller: _emailController,
                hintText: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofocus: true,
                onSubmitted: (_) => _submit(),
              ),

              SizedBox(height: theme.spacing.md),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _submit,
                  style: TextButton.styleFrom(
                    backgroundColor: theme.colors.foreground,
                    foregroundColor: theme.colors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(theme.radius.full),
                    ),
                  ),
                  child: Text('Continue', style: theme.typography.base),
                ),
              ),

              // OR divider + social buttons
              if (config.enabledSocialAuth.isNotEmpty) ...[
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
                ...config.enabledSocialAuth.map(
                  (type) => Padding(
                    padding: EdgeInsets.only(bottom: theme.spacing.sm),
                    child: SocialAuthButton(
                      type: type,
                      onTap: () => widget.controller.signInWithSocial(type),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
