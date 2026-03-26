/// Represents the current authentication state.
enum AuthState {
  /// Initial state, auth status unknown.
  unknown,

  /// User is authenticated.
  authenticated,

  /// User is not authenticated.
  unauthenticated,
}

/// Authenticated user data.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.metadata,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final Map<String, dynamic>? metadata;

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Result of an authentication operation.
sealed class AuthResult {
  const AuthResult();
}

/// Authentication succeeded.
class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user);
  final AuthUser user;
}

/// Authentication failed with an error.
class AuthFailure extends AuthResult {
  const AuthFailure(this.message, {this.code});
  final String message;
  final String? code;
}

/// Email needs verification before completing auth.
class AuthNeedsVerification extends AuthResult {
  const AuthNeedsVerification(this.email);
  final String email;
}

/// Abstract interface for authentication providers.
///
/// Implement this to connect your backend (Firebase, Supabase, custom API).
/// Use [MockAuthProvider] during development.
abstract class AuthProvider {
  // Social auth
  Future<AuthResult> signInWithApple();
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> signInWithMicrosoft();

  // Email auth
  Future<AuthResult> signInWithEmail(String email, String password);
  Future<AuthResult> signUp(String email, String password);

  // Password reset
  Future<void> sendResetEmail(String email);
  Future<AuthResult> confirmResetCode(String email, String code);
  Future<void> resetPassword(String email, String newPassword);

  // Verification
  Future<void> sendVerificationCode(String email);
  Future<AuthResult> verifyCode(String email, String code);

  // Session
  Future<void> signOut();
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;
}
