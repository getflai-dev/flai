/// Configuration for the CMMD API backend.
///
/// Provides base URL and multi-tenancy scoping for all CMMD providers.
/// Use named constructors for common environments:
///
/// ```dart
/// final config = CmmdConfig.dev();           // localhost:3000
/// final config = CmmdConfig.staging();       // staging.cmmd.ai
/// final config = CmmdConfig();               // production cmmd.ai
/// ```
class CmmdConfig {
  /// The base URL for the CMMD API.
  final String baseUrl;

  /// The organization ID for multi-tenancy scoping.
  ///
  /// When set, all requests include an `X-Organization-ID` header.
  final String? organizationId;

  /// Creates a CMMD configuration pointing to production.
  const CmmdConfig({
    this.baseUrl = 'https://cmmd.ai',
    this.organizationId,
  });

  /// Development configuration pointing to localhost.
  const CmmdConfig.dev({this.organizationId})
      : baseUrl = 'http://localhost:3000';

  /// Staging configuration.
  const CmmdConfig.staging({this.organizationId})
      : baseUrl = 'https://staging.cmmd.ai';
}
