import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  String? _csrfToken;
  String? _sessionCookie;
  AuthUser? _currentUser;
  String? _lastEmail;
  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast();
  final StreamController<({String? accessToken, String? refreshToken})>
      _tokenChangeController =
      StreamController<({String? accessToken, String? refreshToken})>
          .broadcast();

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

  @override
  Stream<({String? accessToken, String? refreshToken})> get tokenChanges =>
      _tokenChangeController.stream;

  // ---------------------------------------------------------------------------
  // Email auth
  // ---------------------------------------------------------------------------

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      await _ensureCsrfToken();
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
      return AuthFailure(_friendlyError(e));
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
    try {
      await _ensureCsrfToken();
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
    } catch (e) {
      throw Exception(_friendlyError(e));
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
      await _ensureCsrfToken();
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
      return AuthFailure(_friendlyError(e));
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
      await _ensureCsrfToken();
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
      return AuthFailure(_friendlyError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  @override
  Future<void> signOut() async {
    _setTokens(null, null);
    _setUser(null);
    _csrfToken = null;
    _sessionCookie = null;
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

  @override
  Future<bool> tryRestoreSession(
    String accessToken,
    String refreshToken,
  ) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    try {
      final response = await http.get(
        Uri.parse('${config.baseUrl}/api/me'),
        headers: _baseHeaders,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final user = _parseUser(json);
        _setUser(user);
        _lastEmail = user.email;
        return true;
      }
    } catch (_) {
      // Token may be expired — clear and require re-auth.
    }

    _accessToken = null;
    _refreshToken = null;
    return false;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Map<String, String> get _baseHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        if (_csrfToken != null) ...{
          'X-XSRF-TOKEN': _csrfToken!,
          'Cookie': 'XSRF-TOKEN=$_csrfToken${_sessionCookie ?? ''}',
        },
        if (config.organizationId != null)
          'X-Organization-ID': config.organizationId!,
      };

  /// Fetch a CSRF token from the CMMD API.
  ///
  /// The server uses a double-submit cookie pattern: it sets an
  /// `XSRF-TOKEN` cookie and expects the same value back as the
  /// `X-XSRF-TOKEN` header. We also forward the raw cookie so
  /// the server can verify both match.
  Future<void> _ensureCsrfToken() async {
    if (_csrfToken != null) return;
    try {
      final response = await http.get(
        Uri.parse('${config.baseUrl}/api/csrf-token'),
        headers: {'Accept': 'application/json'},
      );
      final setCookie = response.headers['set-cookie'] ?? '';
      // Extract XSRF token
      final xsrfMatch =
          RegExp(r'XSRF-TOKEN=([^;]+)').firstMatch(setCookie);
      if (xsrfMatch != null) {
        _csrfToken = xsrfMatch.group(1);
      }
      // Capture any session cookie the server sends alongside XSRF
      final sessionMatch =
          RegExp(r'(connect\.sid=[^;]+)').firstMatch(setCookie);
      if (sessionMatch != null) {
        _sessionCookie = '; ${sessionMatch.group(1)}';
      }
    } catch (_) {
      // CSRF fetch failed — proceed without it; server may not require it.
    }
  }

  void _setTokens(String? access, String? refresh) {
    _accessToken = access;
    _refreshToken = refresh;
    onTokenUpdate?.call(access, refresh);
    _tokenChangeController.add((accessToken: access, refreshToken: refresh));
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

  /// Convert a raw exception into a user-friendly error message.
  String _friendlyError(Object e) {
    if (e is SocketException) {
      return 'Could not connect to server. Check your internet connection.';
    }
    if (e is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    if (e is http.ClientException) {
      final msg = e.message;
      if (msg.contains('SocketException') ||
          msg.contains('Connection refused')) {
        return 'Could not connect to server. Check your internet connection.';
      }
      if (msg.contains('timed out') || msg.contains('TimeoutException')) {
        return 'Request timed out. Please try again.';
      }
      return 'Network error. Please try again.';
    }
    if (e is FormatException) {
      return 'Unexpected server response. Please try again.';
    }
    final text = e.toString();
    if (text.contains('SocketException') ||
        text.contains('Connection refused')) {
      return 'Could not connect to server. Check your internet connection.';
    }
    if (text.contains('timed out') || text.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    // Already a user-friendly message (e.g. from API JSON response)
    if (!text.contains('Exception') && text.length < 120) {
      return text;
    }
    return 'Something went wrong. Please try again.';
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
