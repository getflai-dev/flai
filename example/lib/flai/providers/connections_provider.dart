/// Abstract interface for managing third-party service connections
/// (Google, Slack, GitHub, Notion, etc.).
///
/// The settings Connections page reads from a [ConnectionsProvider] to render
/// "Connected" and "Available" sections. Implementations are responsible for
/// the actual OAuth flow — the UI launches an in-app browser with the URL
/// returned by [startConnect].
///
/// Implementations should be pure data adapters: no UI imports, no global
/// state. Provide them via `AppScaffoldConfig.connectionsProvider`.
abstract class ConnectionsProvider {
  /// Loads the catalog of available connectors plus the user's current state.
  Future<List<Connector>> loadConnectors();

  /// Returns an OAuth URL the UI should open in an in-app browser to begin
  /// the connect flow for [connectorId]. The provider is expected to track
  /// the resulting callback out-of-band.
  Future<String> startConnect(String connectorId);

  /// Disconnects the given connector for the current user.
  Future<void> disconnect(String connectorId);
}

/// A single connector entry returned by [ConnectionsProvider.loadConnectors].
class Connector {
  /// Stable identifier used by the backend (e.g. `google_drive`, `slack`).
  final String id;

  /// Display name shown to the user (e.g. "Google Drive").
  final String name;

  /// Short description shown beneath the name in the list.
  final String? description;

  /// Optional URL to a square icon. When null, a default icon is shown.
  final String? iconUrl;

  /// Whether the user has authorized this connector.
  final bool connected;

  /// Optional account label shown when connected (e.g. an email address).
  final String? accountLabel;

  const Connector({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.connected = false,
    this.accountLabel,
  });

  Connector copyWith({bool? connected, String? accountLabel}) => Connector(
        id: id,
        name: name,
        description: description,
        iconUrl: iconUrl,
        connected: connected ?? this.connected,
        accountLabel: accountLabel ?? this.accountLabel,
      );
}
