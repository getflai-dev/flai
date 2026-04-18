import 'dart:convert';

import 'cmmd_client_base.dart';
import 'cmmd_config.dart';
import 'connections_provider.dart';

/// CMMD API implementation of [ConnectionsProvider].
///
/// CMMD exposes a single integrations endpoint that returns the entire catalog
/// plus per-user state and a pre-built OAuth URL for each item:
///
///   * `GET  /api/integrations`                    — list integrations
///   * `POST /api/integrations/{id}/disconnect`    — disconnect
///
/// The list response embeds [Connector.authUrl] so the UI can launch the OAuth
/// flow without a follow-up round-trip. [startConnect] is intentionally
/// unimplemented — fall back to whatever the server returned.
class CmmdConnectionsProvider
    with CmmdClientBase
    implements ConnectionsProvider {
  CmmdConnectionsProvider({
    required this.config,
    required this.accessTokenProvider,
    this.organizationIdProvider,
    this.csrfHeadersProvider,
  });

  @override
  final CmmdConfig config;

  @override
  final String Function() accessTokenProvider;

  @override
  final String? Function()? organizationIdProvider;

  @override
  final Map<String, String> Function()? csrfHeadersProvider;

  @override
  Future<List<Connector>> loadConnectors() async {
    final response = await cmmdGet('/api/integrations');
    final body = jsonDecode(response.body);
    final list = body is List
        ? body
        : (body is Map && body['integrations'] is List
              ? body['integrations'] as List
              : const []);
    return list
        .map((e) => _parseConnector(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<String> startConnect(String connectorId) {
    throw const CmmdApiException(
      message:
          'CMMD embeds the OAuth URL in /api/integrations as `authUrl`; '
          'the UI should launch that directly without calling startConnect.',
    );
  }

  @override
  Future<void> disconnect(String connectorId) async {
    await cmmdPost('/api/integrations/$connectorId/disconnect');
  }

  Connector _parseConnector(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['connectorId'] ?? json['provider'])
        .toString();
    return Connector(
      id: id,
      name: (json['name'] ?? json['displayName'] ?? id).toString(),
      description: json['description']?.toString(),
      iconUrl:
          json['iconUrl']?.toString() ??
          json['serviceLogo']?.toString() ??
          json['icon']?.toString(),
      connected: json['connected'] == true || json['status'] == 'connected',
      accountLabel:
          json['accountLabel']?.toString() ??
          json['accountEmail']?.toString(),
      category: json['category']?.toString(),
      authUrl: json['authUrl']?.toString(),
    );
  }
}
