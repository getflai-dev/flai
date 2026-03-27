import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import 'cmmd_config.dart';

/// CMMD API implementation of [AuthProvider].
///
/// Uses JWT-based authentication against the CMMD backend.
/// Supports email/password, Apple Sign In, Google Sign In,
/// Microsoft OIDC, MFA, and passwordless login code flows.
///
/// ```dart
/// final auth = CmmdAuthProvider(config: CmmdConfig());
/// final result = await auth.signInWithApple();
/// print(auth.accessToken);
/// ```
class CmmdAuthProvider implements AuthProvider {
  /// Creates a [CmmdAuthProvider].
  ///
  /// [config] specifies the CMMD API base URL and organization.
  /// [googleClientId] is required for Google Sign In on iOS.
  /// [microsoftDeepLinkScheme] is the URL scheme for Microsoft OIDC callback.
  CmmdAuthProvider({
    required this.config,
    this.googleClientId,
    this.microsoftDeepLinkScheme = 'cmmd-companion',
  });

  /// The CMMD API configuration.
  final CmmdConfig config;

  /// Google OAuth client ID (required on iOS).
  final String? googleClientId;

  /// URL scheme for Microsoft OIDC callback deep link.
  final String microsoftDeepLinkScheme;

  String? _accessToken;
  String? _refreshToken;
  String? _csrfToken;
  String? _sessionCookie;
  AuthUser? _currentUser;
  String? _lastEmail;
  String? _organizationId;

  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast();
  final StreamController<({String? accessToken, String? refreshToken})>
      _tokenChangeController =
      StreamController<({String? accessToken, String? refreshToken})>
          .broadcast();

  /// The current JWT access token, or `null` if not authenticated.
  String? get accessToken => _accessToken;

  /// The current JWT refresh token, if authenticated.
  String? get refreshToken => _refreshToken;

  /// The organization ID from the last successful login.
  String? get organizationId => _organizationId ?? config.organizationId;

  /// CSRF headers to include in authenticated requests.
  ///
  /// Other CMMD providers (AI, Storage, Voice) should merge these into
  /// their own request headers so that CSRF-protected endpoints work.
  Map<String, String> get csrfHeaders => {
        if (_csrfToken != null) ...{
          'X-XSRF-TOKEN': _csrfToken!,
          'Cookie': 'XSRF-TOKEN=$_csrfToken${_sessionCookie ?? ''}',
        },
      };

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _authStateController.stream;

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
        return AuthFailure(
          _extractError(response) ?? 'Login failed (${response.statusCode})',
          code: '${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // MFA required — return needs-verification so the UI shows the MFA screen.
      if (json['requiresMfa'] == true) {
        _lastEmail = email;
        return AuthNeedsVerification(email);
      }

      return _handleAuthResponse(json, email: email);
    } catch (e) {
      return AuthFailure(_friendlyError(e));
    }
  }

  @override
  Future<AuthResult> signUp(String email, String password) async {
    return const AuthFailure(
      'Sign up is invite-only via cmmd.ai',
      code: 'sign_up_not_supported',
    );
  }

  // ---------------------------------------------------------------------------
  // Social auth — Apple
  // ---------------------------------------------------------------------------

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      // Generate a nonce for validation.
      final rawNonce = _generateNonce();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: rawNonce,
      );

      // Send the identity token to the backend for verification + JWT exchange.
      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/auth/apple'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'identityToken': credential.identityToken,
          'authorizationCode': credential.authorizationCode,
          'email': credential.email,
          'givenName': credential.givenName,
          'familyName': credential.familyName,
          'nonce': rawNonce,
        }),
      );

      if (response.statusCode != 200) {
        return AuthFailure(
          _extractError(response) ?? 'Apple sign-in failed (${response.statusCode})',
          code: '${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _handleAuthResponse(json);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const AuthFailure('Sign in cancelled', code: 'cancelled');
      }
      return AuthFailure('Apple sign-in failed: ${e.message}');
    } catch (e) {
      return AuthFailure(_friendlyError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Social auth — Google
  // ---------------------------------------------------------------------------

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: googleClientId,
        serverClientId: config.googleClientId,
      );

      final account = await googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        return const AuthFailure(
          'Failed to get Google ID token',
          code: 'no_id_token',
        );
      }

      // Exchange the ID token with the backend.
      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/auth/google'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'idToken': idToken,
          'email': account.email,
          'displayName': account.displayName,
          'photoUrl': account.photoUrl,
        }),
      );

      if (response.statusCode != 200) {
        return AuthFailure(
          _extractError(response) ?? 'Google sign-in failed (${response.statusCode})',
          code: '${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _handleAuthResponse(json, email: account.email);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const AuthFailure('Sign in cancelled', code: 'cancelled');
      }
      return AuthFailure('Google sign-in failed: ${e.description ?? e.code}');
    } catch (e) {
      return AuthFailure(_friendlyError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Social auth — Microsoft (OIDC browser flow)
  // ---------------------------------------------------------------------------

  @override
  Future<AuthResult> signInWithMicrosoft() async {
    try {
      final orgId = organizationId;
      if (orgId == null) {
        return const AuthFailure(
          'Organization ID required for Microsoft sign-in',
          code: 'missing_org_id',
        );
      }

      final callbackUrl = '$microsoftDeepLinkScheme://auth/callback';
      final authorizeUrl = Uri.parse(
        '${config.baseUrl}/api/auth/sso/microsoft/authorize'
        '?orgId=$orgId'
        '&returnUrl=${Uri.encodeComponent(callbackUrl)}',
      );

      // Launch the browser for OIDC redirect chain.
      final launched = await launchUrl(
        authorizeUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        return const AuthFailure(
          'Could not open browser for Microsoft sign-in',
          code: 'browser_launch_failed',
        );
      }

      // The JWT will come back via deep link (handled by the app's deep link handler).
      // Return a pending result — the app scaffold listens for the callback URI
      // and calls handleMicrosoftCallback() when it arrives.
      return const AuthFailure(
        'Waiting for Microsoft sign-in callback...',
        code: 'awaiting_callback',
      );
    } catch (e) {
      return AuthFailure(_friendlyError(e));
    }
  }

  /// Handle the deep link callback from Microsoft OIDC flow.
  ///
  /// Call this from your app's deep link handler when you receive a
  /// `cmmd-companion://auth/callback?token=...&refreshToken=...` URI.
  Future<AuthResult> handleMicrosoftCallback(Uri callbackUri) async {
    final token = callbackUri.queryParameters['token'];
    final refresh = callbackUri.queryParameters['refreshToken'];

    if (token == null) {
      final error = callbackUri.queryParameters['error'];
      return AuthFailure(error ?? 'Microsoft sign-in failed');
    }

    _setTokens(token, refresh);

    // Validate the token to get user data.
    try {
      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/auth/validate'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final user = _parseUser(json);
        _setUser(user);
        return AuthSuccess(user);
      }
    } catch (_) {
      // Validation failed but we have the token — try to use it anyway.
    }

    // Fallback: create a minimal user from the token.
    final user = AuthUser(id: 'microsoft', email: '');
    _setUser(user);
    return AuthSuccess(user);
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
        throw Exception(
          _extractError(response) ??
              'Failed to send reset email (${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception(_friendlyError(e));
    }
  }

  @override
  Future<AuthResult> confirmResetCode(String email, String code) async {
    return verifyCode(email, code);
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    // CMMD handles password reset via email link, not in-app.
    throw UnimplementedError(
      'CMMD handles password reset server-side via email link.',
    );
  }

  // ---------------------------------------------------------------------------
  // Verification / Passwordless
  // ---------------------------------------------------------------------------

  @override
  Future<void> sendVerificationCode(String email) async {
    _lastEmail = email;
    try {
      await _ensureCsrfToken();
      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/request-login-code'),
        headers: _baseHeaders,
        body: jsonEncode({'identifier': email}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response) ??
              'Failed to send login code (${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception(_friendlyError(e));
    }
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
        return AuthFailure(
          _extractError(response) ??
              'Verification failed (${response.statusCode})',
          code: '${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json.containsKey('token')) {
        return _handleAuthResponse(json, email: email);
      }

      return const AuthFailure('Verification succeeded but no token returned.');
    } catch (e) {
      return AuthFailure(_friendlyError(e));
    }
  }

  /// Verify a multi-factor authentication code.
  ///
  /// Called when login returns `requiresMfa: true`. Uses the email
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
          'username': email,
          'code': code,
          'trustDevice': false,
        }),
      );

      if (response.statusCode != 200) {
        return AuthFailure(
          _extractError(response) ??
              'MFA verification failed (${response.statusCode})',
          code: '${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _handleAuthResponse(json, email: email);
    } catch (e) {
      return AuthFailure(_friendlyError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Check user (does email exist?)
  // ---------------------------------------------------------------------------

  /// Check if a user exists for the given email.
  ///
  /// Returns `true` if the user exists. The [profile] field in the response
  /// contains basic profile info (firstName, lastName, profileImage).
  Future<({bool exists, Map<String, dynamic>? profile})> checkUser(
    String email,
  ) async {
    try {
      final encoded = Uri.encodeQueryComponent(email);
      final response = await http.get(
        Uri.parse('${config.baseUrl}/api/auth/check-user?identifier=$encoded'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (
          exists: json['exists'] as bool? ?? false,
          profile: json['profile'] as Map<String, dynamic>?,
        );
      }
      return (exists: false, profile: null);
    } catch (_) {
      return (exists: false, profile: null);
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
    _organizationId = null;
  }

  // ---------------------------------------------------------------------------
  // Token restoration
  // ---------------------------------------------------------------------------

  @override
  Future<bool> tryRestoreSession(
    String accessToken,
    String? refreshToken,
  ) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    try {
      await _ensureCsrfToken();
      final response = await http
          .post(
            Uri.parse('${config.baseUrl}/api/auth/validate'),
            headers: _baseHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['valid'] == true) {
          final user = _parseUser(json);
          _setUser(user);
          _lastEmail = user.email;
          return true;
        }
      }
    } catch (_) {
      // Token may be expired or network unavailable — clear and require re-auth.
    }

    _accessToken = null;
    _refreshToken = null;
    return false;
  }

  /// Restore a previously persisted session synchronously.
  ///
  /// Call this at app startup with tokens + user from secure storage.
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
        'User-Agent': 'FlAI/1.0 (cmmd_providers)',
        'X-Auth-Type': 'jwt',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
        if (_csrfToken != null) ...{
          'X-XSRF-TOKEN': _csrfToken!,
          'Cookie': 'XSRF-TOKEN=$_csrfToken${_sessionCookie ?? ''}',
        },
        'X-Organization-ID': ?organizationId,
      };

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'FlAI/1.0 (cmmd_providers)',
        'Authorization': 'Bearer $token',
        'X-Auth-Type': 'jwt',
        'X-Organization-ID': ?organizationId,
      };

  Future<void> _ensureCsrfToken() async {
    if (_csrfToken != null) return;
    try {
      final response = await http.get(
        Uri.parse('${config.baseUrl}/api/csrf-token'),
        headers: {'Accept': 'application/json'},
      );
      final setCookie = response.headers['set-cookie'] ?? '';
      final xsrfMatch =
          RegExp(r'XSRF-TOKEN=([^;]+)').firstMatch(setCookie);
      if (xsrfMatch != null) {
        _csrfToken = xsrfMatch.group(1);
      }
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
    _tokenChangeController.add((accessToken: access, refreshToken: refresh));
  }

  void _setUser(AuthUser? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  /// Common handler for all successful auth responses.
  ///
  /// Extracts JWT tokens, user data, and organization ID.
  AuthResult _handleAuthResponse(
    Map<String, dynamic> json, {
    String? email,
  }) {
    _setTokens(
      json['token'] as String?,
      json['refreshToken'] as String?,
    );

    // Store organization ID for subsequent requests.
    final orgId = json['defaultOrganizationId'];
    if (orgId != null) {
      _organizationId = orgId.toString();
    }

    final user = _parseUser(json);
    _setUser(user);
    if (email != null) _lastEmail = email;

    return AuthSuccess(user);
  }

  AuthUser _parseUser(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? json;
    return AuthUser(
      id: (userJson['id'] ?? '').toString(),
      email: userJson['email'] as String? ?? '',
      displayName:
          userJson['firstName'] as String? ?? userJson['username'] as String?,
      photoUrl: userJson['profileImageUrl'] as String? ??
          userJson['profileImage'] as String?,
      metadata: {
        if (json.containsKey('defaultOrganizationId'))
          'defaultOrganizationId': json['defaultOrganizationId'],
        if (json.containsKey('organizations'))
          'organizations': json['organizations'],
      },
    );
  }

  /// Extract error message from a response body.
  String? _extractError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['error'] as String? ?? json['message'] as String?;
    } catch (_) {
      return null;
    }
  }

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
      return 'Network error. Please try again.';
    }
    final text = e.toString();
    if (text.contains('SocketException') ||
        text.contains('Connection refused')) {
      return 'Could not connect to server. Check your internet connection.';
    }
    if (!text.contains('Exception') && text.length < 120) {
      return text;
    }
    return 'Something went wrong. Please try again.';
  }

  /// Generate a random nonce string for Apple Sign In.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }
}
