import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../providers/auth_provider.dart';
import 'auth_flow_config.dart';

/// Auth flow screen identifiers.
enum AuthScreen {
  loginLanding,
  emailEntry,
  passwordEntry,
  forgotPassword,
  verificationCode,
  resetPassword,
}

/// Reason the verification code screen is shown.
enum VerificationReason { signUp, resetPassword }

/// Controller managing the auth flow state machine.
///
/// Handles screen navigation, loading states, error messages,
/// and delegates to [AuthProvider] for actual auth operations.
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthProvider provider,
    required AuthFlowConfig config,
    this.onAuthenticated,
    this.onGuestContinue,
  })  : _provider = provider,
        _config = config;

  final AuthProvider _provider;
  final AuthFlowConfig _config;

  /// Called when authentication succeeds.
  final void Function(AuthUser user)? onAuthenticated;

  /// Called when guest mode is selected.
  final VoidCallback? onGuestContinue;

  // State
  AuthScreen _currentScreen = AuthScreen.loginLanding;
  bool _isLoading = false;
  String? _errorMessage;
  String _email = '';
  VerificationReason _verificationReason = VerificationReason.signUp;
  bool _isSignUpMode = false;

  // Getters
  AuthScreen get currentScreen => _currentScreen;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get email => _email;
  AuthFlowConfig get config => _config;
  VerificationReason get verificationReason => _verificationReason;
  bool get isSignUpMode => _isSignUpMode;

  // Navigation

  /// Navigate to a screen in the auth flow.
  void goTo(AuthScreen screen) {
    _errorMessage = null;
    _currentScreen = screen;
    notifyListeners();
  }

  /// Navigate to email entry, setting sign-up mode.
  void goToEmailEntry({required bool isSignUp}) {
    _isSignUpMode = isSignUp;
    goTo(AuthScreen.emailEntry);
  }

  /// Go back to the previous logical screen.
  void goBack() {
    _errorMessage = null;
    switch (_currentScreen) {
      case AuthScreen.loginLanding:
        break; // Already at root
      case AuthScreen.emailEntry:
        _currentScreen = AuthScreen.loginLanding;
      case AuthScreen.passwordEntry:
        _currentScreen = AuthScreen.emailEntry;
      case AuthScreen.forgotPassword:
        _currentScreen = AuthScreen.passwordEntry;
      case AuthScreen.verificationCode:
        _currentScreen = _verificationReason == VerificationReason.resetPassword
            ? AuthScreen.forgotPassword
            : AuthScreen.emailEntry;
      case AuthScreen.resetPassword:
        _currentScreen = AuthScreen.verificationCode;
    }
    notifyListeners();
  }

  // Actions

  /// Submit email and proceed to password entry.
  void submitEmail(String email) {
    _email = email;
    _errorMessage = null;
    _currentScreen = AuthScreen.passwordEntry;
    notifyListeners();
  }

  /// Sign in with email and password.
  Future<void> signInWithEmail(String password) async {
    await _runAsync(() async {
      final result = await _provider.signInWithEmail(_email, password);
      _handleResult(result);
    });
  }

  /// Sign up with email and password.
  Future<void> signUp(String password) async {
    await _runAsync(() async {
      final result = await _provider.signUp(_email, password);
      _handleResult(result);
    });
  }

  /// Sign in with a social provider.
  Future<void> signInWithSocial(SocialAuthType type) async {
    await _runAsync(() async {
      final result = switch (type) {
        SocialAuthType.apple => await _provider.signInWithApple(),
        SocialAuthType.google => await _provider.signInWithGoogle(),
        SocialAuthType.microsoft => await _provider.signInWithMicrosoft(),
        SocialAuthType.phone =>
          throw UnimplementedError('Phone auth not yet supported'),
      };
      _handleResult(result);
    });
  }

  /// Send password reset email.
  Future<void> sendResetEmail() async {
    await _runAsync(() async {
      await _provider.sendResetEmail(_email);
      _verificationReason = VerificationReason.resetPassword;
      _currentScreen = AuthScreen.verificationCode;
    });
  }

  /// Verify a code (for signup or password reset).
  Future<void> verifyCode(String code) async {
    await _runAsync(() async {
      final result = await _provider.verifyCode(_email, code);
      switch (result) {
        case AuthSuccess(:final user):
          if (_verificationReason == VerificationReason.resetPassword) {
            _currentScreen = AuthScreen.resetPassword;
          } else {
            onAuthenticated?.call(user);
          }
        case AuthFailure(:final message):
          _errorMessage = message;
        case AuthNeedsVerification():
          break; // Stay on verification screen
      }
    });
  }

  /// Resend verification code.
  Future<void> resendCode() async {
    await _runAsync(() async {
      await _provider.sendVerificationCode(_email);
    });
  }

  /// Reset password with new password.
  Future<void> resetPassword(String newPassword) async {
    await _runAsync(() async {
      await _provider.resetPassword(_email, newPassword);
      // Auto-login after reset
      final result = await _provider.signInWithEmail(_email, newPassword);
      _handleResult(result);
    });
  }

  // Private helpers

  void _handleResult(AuthResult result) {
    switch (result) {
      case AuthSuccess(:final user):
        onAuthenticated?.call(user);
      case AuthFailure(:final message):
        _errorMessage = message;
      case AuthNeedsVerification(:final email):
        _email = email;
        _verificationReason = VerificationReason.signUp;
        _currentScreen = AuthScreen.verificationCode;
    }
  }

  Future<void> _runAsync(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
