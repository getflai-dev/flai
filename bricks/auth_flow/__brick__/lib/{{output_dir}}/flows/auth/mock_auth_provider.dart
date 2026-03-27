import 'dart:async';

import '../../providers/auth_provider.dart';

/// Mock auth provider for development and testing.
///
/// Simulates authentication with a configurable delay.
/// All operations succeed by default. Set [shouldFail] to true
/// to simulate auth failures.
class MockAuthProvider implements AuthProvider {
  MockAuthProvider({
    this.delay = const Duration(milliseconds: 800),
    this.shouldFail = false,
  });

  final Duration delay;
  final bool shouldFail;

  AuthUser? _currentUser;
  final _authStateController = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _authStateController.stream;

  Future<AuthResult> _simulate(AuthUser user) async {
    await Future<void>.delayed(delay);
    if (shouldFail) {
      return const AuthFailure('Mock auth failure', code: 'mock_error');
    }
    _currentUser = user;
    _authStateController.add(user);
    return AuthSuccess(user);
  }

  AuthUser _mockUser(String email) => AuthUser(
        id: 'mock_${email.hashCode}',
        email: email,
        displayName: email.split('@').first,
      );

  @override
  Future<AuthResult> signInWithApple() =>
      _simulate(_mockUser('apple@example.com'));

  @override
  Future<AuthResult> signInWithGoogle() =>
      _simulate(_mockUser('google@example.com'));

  @override
  Future<AuthResult> signInWithMicrosoft() =>
      _simulate(_mockUser('microsoft@example.com'));

  @override
  Future<AuthResult> signInWithEmail(String email, String password) =>
      _simulate(_mockUser(email));

  @override
  Future<AuthResult> signUp(String email, String password) async {
    await Future<void>.delayed(delay);
    if (shouldFail) {
      return const AuthFailure('Mock signup failure', code: 'mock_error');
    }
    return AuthNeedsVerification(email);
  }

  @override
  Future<void> sendResetEmail(String email) async {
    await Future<void>.delayed(delay);
  }

  @override
  Future<AuthResult> confirmResetCode(String email, String code) async {
    await Future<void>.delayed(delay);
    if (shouldFail || code != '123456') {
      return const AuthFailure('Invalid code', code: 'invalid_code');
    }
    return AuthSuccess(_mockUser(email));
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    await Future<void>.delayed(delay);
  }

  @override
  Future<void> sendVerificationCode(String email) async {
    await Future<void>.delayed(delay);
  }

  @override
  Future<AuthResult> verifyCode(String email, String code) async {
    await Future<void>.delayed(delay);
    if (shouldFail || code != '123456') {
      return const AuthFailure('Invalid code', code: 'invalid_code');
    }
    return _simulate(_mockUser(email));
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(delay);
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<bool> tryRestoreSession(
    String accessToken,
    String refreshToken,
  ) async =>
      false;

  @override
  Stream<({String? accessToken, String? refreshToken})> get tokenChanges =>
      const Stream.empty();

  /// Dispose the stream controller.
  void dispose() {
    _authStateController.close();
  }
}
