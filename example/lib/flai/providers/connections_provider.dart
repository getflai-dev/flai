/// Abstract interface for managing third-party service connections
/// (Salesforce, Google, Slack, GitHub, Notion, etc.).
///
/// The settings Connections page reads from a [ConnectionsProvider] to render
/// "Connected" and "Available" sections. Implementations are responsible for
/// the actual OAuth flow — the UI launches an in-app browser with either
/// [Connector.authUrl] (preferred — pre-built by the backend) or whatever
/// [startConnect] returns when no inline URL is available.
abstract class ConnectionsProvider {
  /// Loads the catalog of available connectors plus the user's current state.
  Future<List<Connector>> loadConnectors();

  /// Returns an OAuth URL for [connectorId]. Implementations may call this
  /// when [Connector.authUrl] is null, or to refresh the URL/state token.
  /// The default implementation throws — most backends should embed
  /// `authUrl` in the connector payload directly.
  Future<String> startConnect(String connectorId) =>
      throw UnimplementedError(
        'startConnect() not implemented; supply Connector.authUrl instead.',
      );

  /// Disconnects the given connector for the current user.
  Future<void> disconnect(String connectorId);
}

/// A single connector entry returned by [ConnectionsProvider.loadConnectors].
class Connector {
  /// Stable identifier used by the backend (e.g. `salesforce`, `slack`).
  final String id;

  /// Display name shown to the user (e.g. "Salesforce").
  final String name;

  /// Short description shown beneath the name in the list.
  final String? description;

  /// Optional URL to a square icon. When null, a default icon is shown.
  final String? iconUrl;

  /// Whether the user has authorized this connector.
  final bool connected;

  /// Optional account label shown when connected (e.g. an email address).
  final String? accountLabel;

  /// Optional grouping category (e.g. "crm", "productivity", "finance").
  /// Used by the UI to render section headings within the Available list.
  final String? category;

  /// Pre-built OAuth authorization URL — when present, the UI opens this
  /// directly without a separate call to [ConnectionsProvider.startConnect].
  final String? authUrl;

  const Connector({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.connected = false,
    this.accountLabel,
    this.category,
    this.authUrl,
  });

  Connector copyWith({bool? connected, String? accountLabel}) => Connector(
        id: id,
        name: name,
        description: description,
        iconUrl: iconUrl,
        connected: connected ?? this.connected,
        accountLabel: accountLabel ?? this.accountLabel,
        category: category,
        authUrl: authUrl,
      );
}
