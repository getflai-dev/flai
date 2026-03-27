/// Configuration for the CMMD API backend.
///
/// Provides base URL, organization scoping, and Google OAuth client ID
/// for all CMMD providers.
///
/// ```dart
/// final config = CmmdConfig.dev();           // localhost:3000
/// final config = CmmdConfig.staging();       // staging.cmmd.ai
/// final config = CmmdConfig();               // production cmmd.ai
/// ```
///
/// All authenticated requests include these headers:
/// - `Authorization: Bearer <jwt>`
/// - `X-Auth-Type: jwt`
/// - `X-Organization-ID: <id>` (when [organizationId] is set)
class CmmdConfig {
  /// The base URL for the CMMD API.
  final String baseUrl;

  /// The organization ID for multi-tenancy scoping.
  ///
  /// When set, all requests include an `X-Organization-ID` header.
  /// This is typically set from the `defaultOrganizationId` in the
  /// login response.
  final String? organizationId;

  /// Google OAuth client ID for Google Sign In on iOS.
  ///
  /// Required for `CmmdAuthProvider.signInWithGoogle()` to work on iOS.
  /// Get this from your Google Cloud Console OAuth 2.0 credentials.
  final String? googleClientId;

  /// URL scheme for Microsoft OIDC deep link callback.
  ///
  /// Defaults to `cmmd-companion`. The callback URL is
  /// `{microsoftDeepLinkScheme}://auth/callback`.
  final String microsoftDeepLinkScheme;

  /// Creates a CMMD configuration pointing to production.
  const CmmdConfig({
    this.baseUrl = 'https://cmmd.ai',
    this.organizationId,
    this.googleClientId,
    this.microsoftDeepLinkScheme = 'cmmd-companion',
  });

  /// Development configuration pointing to localhost.
  const CmmdConfig.dev({
    this.organizationId,
    this.googleClientId,
    this.microsoftDeepLinkScheme = 'cmmd-companion',
  }) : baseUrl = 'http://localhost:3000';

  /// Staging configuration.
  const CmmdConfig.staging({
    this.organizationId,
    this.googleClientId,
    this.microsoftDeepLinkScheme = 'cmmd-companion',
  }) : baseUrl = 'https://staging.cmmd.ai';
}
