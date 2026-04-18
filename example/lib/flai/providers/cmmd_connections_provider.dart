import 'dart:convert';

import 'cmmd_client_base.dart';
import 'cmmd_config.dart';
import 'connections_provider.dart';

/// CMMD API implementation of [ConnectionsProvider].
///
/// The CMMD web client backs `/connections` with these endpoints:
///
///   * `GET    /api/connections`                 — list connectors + state
///   * `POST   /api/connections/{id}/oauth-url`  — returns OAuth URL
///   * `DELETE /api/connections/{id}`            — disconnect
///
/// On API errors a [CmmdApiException] is thrown so the UI can surface a
/// friendly message via [CmmdClientBase.friendlyError]. If the production
/// backend renames endpoints, retune them here — the [Connector] shape stays
/// the same.
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
    final response = await cmmdGet('/api/connections');
    final body = jsonDecode(response.body);
    final list = body is List
        ? body
        : (body is Map && body['connectors'] is List
            ? body['connectors'] as List
            : const []);
    return list
        .map((e) => _parseConnector(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<String> startConnect(String connectorId) async {
    final response = await cmmdPost('/api/connections/$connectorId/oauth-url');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final url = body['url'] ?? body['oauthUrl'] ?? body['authorizationUrl'];
    if (url is! String || url.isEmpty) {
      throw const CmmdApiException(message: 'No OAuth URL returned by server.');
    }
    return url;
  }

  @override
  Future<void> disconnect(String connectorId) async {
    await cmmdDelete('/api/connections/$connectorId');
  }

  Connector _parseConnector(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['connectorId'] ?? json['provider']).toString();
    return Connector(
      id: id,
      name: (json['name'] ?? json['displayName'] ?? id).toString(),
      description: json['description']?.toString(),
      iconUrl: json['iconUrl']?.toString() ?? json['icon']?.toString(),
      connected: json['connected'] == true || json['status'] == 'connected',
      accountLabel: json['accountLabel']?.toString() ?? json['accountEmail']?.toString(),
    );
  }
}
