import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../providers/auth_provider.dart';
import 'cmmd_config.dart';

/// CMMD API implementation of [AuthProvider].
///
/// Uses JWT-based authentication against the CMMD backend.
/// Tokens are stored in memory; use [onTokenUpdate] to persist
/// them in secure storage on the consumer side.
///
/// ```dart
/// final auth = CmmdAuthProvider(
///   config: CmmdConfig(),
///   onTokenUpdate: (access, refresh) {
///     secureStorage.write('access', access);
///     secureStorage.write('refresh', refresh);
///   },
/// );
/// ```
class CmmdAuthProvider implements AuthProvider {
  /// Creates a [CmmdAuthProvider].
  ///
  /// [config] specifies the CMMD API base URL and organization.
  /// [onTokenUpdate] is called whenever tokens change so the consumer
  /// can persist them in secure storage.
  CmmdAuthProvider({
    required this.config,
    this.onTokenUpdate,
  });

  /// The CMMD API configuration.
  final CmmdConfig config;

  /// Callback invoked when access or refresh tokens change.
  ///
  /// Called with `null` values on sign-out.
  final void Function(String? accessToken, String? refreshToken)? onTokenUpdate;

  String? _accessToken;
  String? _refreshToken;
  AuthUser? _currentUser;
  String? _lastEmail;
  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast();

  /// The current JWT refresh token, if authenticated.
  String? get refreshToken => _refreshToken;

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _authStateController.stream;

  /// The current JWT access token, or `null` if not authenticated.
  String? get accessToken => _accessToken;

  // ---------------------------------------------------------------------------
  // Email auth
  // ---------------------------------------------------------------------------

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/login'),
        headers: {
          ..._baseHeaders,
          'x-auth-type': 'jwt',
        },
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        final body = _tryDecodeBody(response.body);
        final message =
            body?['message'] as String? ?? 'Login failed (${response.statusCode})';
        return AuthFailure(message, code: '${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _setTokens(
        json['token'] as String?,
        json['refreshToken'] as String?,
      );

      final user = _parseUser(json);
      _setUser(user);
      _lastEmail = email;

      return AuthSuccess(user);
    } catch (e) {
      return AuthFailure(e.toString());
    }
  }

  @override
  Future<AuthResult> signUp(String email, String password) async {
    // CMMD does not expose a separate mobile sign-up endpoint.
    // Direct users to the web application.
    return const AuthFailure(
      'Sign up via web at cmmd.ai',
      code: 'sign_up_not_supported',
    );
  }

  // ---------------------------------------------------------------------------
  // Social auth
  // ---------------------------------------------------------------------------

  @override
  Future<AuthResult> signInWithApple() async {
    return const AuthFailure(
      'Apple sign-in requires a web browser. Use cmmd.ai to authenticate.',
      code: 'social_auth_not_supported',
    );
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    return const AuthFailure(
      'Google sign-in requires a web browser. Use cmmd.ai to authenticate.',
      code: 'social_auth_not_supported',
    );
  }

  @override
  Future<AuthResult> signInWithMicrosoft() async {
    return const AuthFailure(
      'Microsoft sign-in requires a web browser. Use cmmd.ai to authenticate.',
      code: 'social_auth_not_supported',
    );
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------

  @override
  Future<void> sendResetEmail(String email) async {
    _lastEmail = email;
    final response = await http.post(
      Uri.parse('${config.baseUrl}/api/forgot-password'),
      headers: _baseHeaders,
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final body = _tryDecodeBody(response.body);
      throw Exception(
        body?['message'] as String? ??
            'Failed to send reset email (${response.statusCode})',
      );
    }
  }

  @override
  Future<AuthResult> confirmResetCode(String email, String code) async {
    // CMMD uses verify-login-code for OTP confirmation during reset flow.
    return verifyCode(email, code);
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    // After verification, the password reset is handled server-side
    // via the token from verification. This is a no-op placeholder
    // as CMMD handles the full flow through verify-login-code.
    throw UnimplementedError(
      'CMMD handles password reset server-side after code verification.',
    );
  }

  // ---------------------------------------------------------------------------
  // Verification
  // ---------------------------------------------------------------------------

  @override
  Future<void> sendVerificationCode(String email) async {
    // Verification codes are sent automatically by CMMD during login
    // when MFA is enabled. This triggers a new code via forgot-password.
    _lastEmail = email;
    await sendResetEmail(email);
  }

  @override
  Future<AuthResult> verifyCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/verify-login-code'),
        headers: _baseHeaders,
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      if (response.statusCode != 200) {
        final body = _tryDecodeBody(response.body);
        final message =
            body?['message'] as String? ?? 'Verification failed (${response.statusCode})';
        return AuthFailure(message, code: '${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // If the response includes tokens, the user is now authenticated.
      if (json.containsKey('token')) {
        _setTokens(
          json['token'] as String?,
          json['refreshToken'] as String?,
        );
        final user = _parseUser(json);
        _setUser(user);
        return AuthSuccess(user);
      }

      return const AuthFailure('Verification succeeded but no token returned.');
    } catch (e) {
      return AuthFailure(e.toString());
    }
  }

  /// Verify a multi-factor authentication code.
  ///
  /// Called when the login flow requires MFA. Uses the stored email
  /// from the last sign-in attempt.
  Future<AuthResult> verifyMfa(String code) async {
    final email = _lastEmail;
    if (email == null) {
      return const AuthFailure(
        'No email context for MFA verification.',
        code: 'missing_email',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/verify-mfa'),
        headers: _baseHeaders,
        body: jsonEncode({
          'code': code,
          'username': email,
        }),
      );

      if (response.statusCode != 200) {
        final body = _tryDecodeBody(response.body);
        final message =
            body?['message'] as String? ?? 'MFA verification failed (${response.statusCode})';
        return AuthFailure(message, code: '${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _setTokens(
        json['token'] as String?,
        json['refreshToken'] as String?,
      );

      final user = _parseUser(json);
      _setUser(user);

      return AuthSuccess(user);
    } catch (e) {
      return AuthFailure(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  @override
  Future<void> signOut() async {
    _setTokens(null, null);
    _setUser(null);
    _lastEmail = null;
  }

  // ---------------------------------------------------------------------------
  // Token restoration
  // ---------------------------------------------------------------------------

  /// Restore a previously persisted session.
  ///
  /// Call this at app startup with tokens retrieved from secure storage.
  /// The [user] should be the previously cached [AuthUser].
  void restoreSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _currentUser = user;
    _lastEmail = user.email;
    _authStateController.add(user);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Map<String, String> get _baseHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        if (config.organizationId != null)
          'X-Organization-ID': config.organizationId!,
      };

  void _setTokens(String? access, String? refresh) {
    _accessToken = access;
    _refreshToken = refresh;
    onTokenUpdate?.call(access, refresh);
  }

  void _setUser(AuthUser? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  /// Parse a CMMD user JSON payload into an [AuthUser].
  AuthUser _parseUser(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? json;
    return AuthUser(
      id: userJson['id'].toString(),
      email: userJson['email'] as String? ?? '',
      displayName:
          userJson['firstName'] as String? ?? userJson['username'] as String?,
      photoUrl: userJson['profileImageUrl'] as String?,
      metadata: {
        if (json.containsKey('defaultOrganizationId'))
          'defaultOrganizationId': json['defaultOrganizationId'],
      },
    );
  }

  /// Attempt to decode a JSON response body, returning `null` on failure.
  Map<String, dynamic>? _tryDecodeBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
