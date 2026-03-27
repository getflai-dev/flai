import 'package:flutter/widgets.dart';

/// Types of social authentication supported.
enum SocialAuthType { apple, google, microsoft, phone }

/// Configuration for the auth flow screens.
///
/// Controls which auth methods are visible, branding, and legal links.
class AuthFlowConfig {
  const AuthFlowConfig({
    this.showAppleSignIn = true,
    this.showGoogleSignIn = true,
    this.showMicrosoftSignIn = false,
    this.showPhoneSignIn = false,
    this.showEmailSignIn = true,
    this.showSignUp = true,
    this.allowGuest = false,
    this.appLogo,
    this.taglines = const [
      "Let's brainstorm",
      "Let's collaborate",
      "Let's create",
    ],
    this.emailHeading = 'Log in or sign up',
    this.emailSubtitle,
    this.termsUrl,
    this.privacyUrl,
    this.onGuestContinue,
  });

  /// Show "Continue with Apple" button.
  final bool showAppleSignIn;

  /// Show "Continue with Google" button.
  final bool showGoogleSignIn;

  /// Show "Continue with Microsoft" button.
  final bool showMicrosoftSignIn;

  /// Show "Continue with phone" button.
  final bool showPhoneSignIn;

  /// Show email/password sign-in option.
  final bool showEmailSignIn;

  /// Show "Sign up" button. Set false for private/invite-only apps.
  final bool showSignUp;

  /// Show dismiss (X) button for guest/skip mode.
  final bool allowGuest;

  /// Custom logo widget displayed on all auth screens.
  final Widget? appLogo;

  /// Rotating taglines on the login landing screen.
  final List<String> taglines;

  /// Heading text on the email entry screen.
  final String emailHeading;

  /// Subtitle text on the email entry screen.
  final String? emailSubtitle;

  /// URL for Terms of Use link.
  final String? termsUrl;

  /// URL for Privacy Policy link.
  final String? privacyUrl;

  /// Called when guest mode dismiss button is tapped.
  final VoidCallback? onGuestContinue;

  /// Returns the list of enabled social auth types.
  List<SocialAuthType> get enabledSocialAuth {
    return [
      if (showAppleSignIn) SocialAuthType.apple,
      if (showGoogleSignIn) SocialAuthType.google,
      if (showMicrosoftSignIn) SocialAuthType.microsoft,
      if (showPhoneSignIn) SocialAuthType.phone,
    ];
  }
}
