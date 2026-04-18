import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/flai_theme.dart';
import '../../providers.dart';
import '../../providers/connections_provider.dart';
import '../../providers/cmmd_client_base.dart';

/// Settings → Connections page.
///
/// Renders two sections — Connected and Available — sourced from the
/// configured [ConnectionsProvider]. OAuth flows open in an in-app browser
/// via [url_launcher]. After a successful OAuth round-trip the list is
/// refreshed, so we stay in sync without requiring a deep-link callback.
class FlaiConnectionsScreen extends StatefulWidget {
  const FlaiConnectionsScreen({super.key});

  @override
  State<FlaiConnectionsScreen> createState() => _FlaiConnectionsScreenState();
}

class _FlaiConnectionsScreenState extends State<FlaiConnectionsScreen> {
  late Future<List<Connector>> _future;
  ConnectionsProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = FlaiProviders.of(context).connectionsProvider;
    if (provider != _provider) {
      _provider = provider;
      _future = _load();
    }
  }

  Future<List<Connector>> _load() async {
    final provider = _provider;
    if (provider == null) return const [];
    return provider.loadConnectors();
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        backgroundColor: theme.colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.colors.foreground),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Connections',
          style: theme.typography.lg.copyWith(
            color: theme.colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.colors.foreground),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _provider == null
          ? _EmptyState(
              icon: Icons.cable_rounded,
              title: 'Connections not configured',
              subtitle:
                  'Pass a ConnectionsProvider to AppScaffoldConfig to enable\nthird-party integrations.',
            )
          : FutureBuilder<List<Connector>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: CmmdClientBase.friendlyError(snapshot.error!),
                    onRetry: _refresh,
                  );
                }
                final connectors = snapshot.data ?? const [];
                if (connectors.isEmpty) {
                  return _EmptyState(
                    icon: Icons.extension_outlined,
                    title: 'No connectors available',
                    subtitle:
                        'Your workspace has no integrations enabled yet.',
                  );
                }
                final connected =
                    connectors.where((c) => c.connected).toList();
                final available =
                    connectors.where((c) => !c.connected).toList();
                return ListView(
                  padding: EdgeInsets.symmetric(vertical: theme.spacing.sm),
                  children: [
                    if (connected.isNotEmpty) ...[
                      _SectionHeader('Connected'),
                      for (final c in connected)
                        _ConnectorRow(
                          connector: c,
                          onTap: () => _disconnect(c),
                          actionLabel: 'Disconnect',
                          destructive: true,
                        ),
                    ],
                    if (available.isNotEmpty) ...[
                      _SectionHeader('Available'),
                      for (final c in available)
                        _ConnectorRow(
                          connector: c,
                          onTap: () => _connect(c),
                          actionLabel: 'Connect',
                        ),
                    ],
                  ],
                );
              },
            ),
    );
  }

  Future<void> _connect(Connector c) async {
    final provider = _provider;
    if (provider == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = c.authUrl ?? await provider.startConnect(c.id);
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.inAppBrowserView,
      );
      if (!ok) throw Exception('Could not open the OAuth window.');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(CmmdClientBase.friendlyError(e))),
      );
    }
    _refresh();
  }

  Future<void> _disconnect(Connector c) async {
    final provider = _provider;
    if (provider == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Disconnect ${c.name}?'),
        content: Text(
          'CMMD will stop pulling data from ${c.name}. You can reconnect anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await provider.disconnect(c.id);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(CmmdClientBase.friendlyError(e))),
      );
    }
    _refresh();
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.md,
        theme.spacing.md,
        theme.spacing.md,
        theme.spacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: theme.typography.sm.copyWith(
          color: theme.colors.mutedForeground,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ConnectorRow extends StatelessWidget {
  final Connector connector;
  final VoidCallback onTap;
  final String actionLabel;
  final bool destructive;

  const _ConnectorRow({
    required this.connector,
    required this.onTap,
    required this.actionLabel,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.md,
        vertical: theme.spacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colors.muted,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: connector.iconUrl != null
                ? ClipOval(
                    child: Image.network(
                      connector.iconUrl!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.extension_outlined,
                        size: 20,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  )
                : Icon(
                    Icons.extension_outlined,
                    size: 20,
                    color: theme.colors.mutedForeground,
                  ),
          ),
          SizedBox(width: theme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  connector.name,
                  style: theme.typography.base.copyWith(
                    color: theme.colors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (connector.accountLabel != null)
                  Text(
                    connector.accountLabel!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  )
                else if (connector.description != null)
                  Text(
                    connector.description!,
                    style: theme.typography.sm.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  destructive ? theme.colors.destructive : theme.colors.foreground,
              side: BorderSide(color: theme.colors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.radius.sm),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.md,
                vertical: theme.spacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: theme.typography.sm.copyWith(
                color: destructive
                    ? theme.colors.destructive
                    : theme.colors.foreground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colors.mutedForeground),
            SizedBox(height: theme.spacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.typography.lg.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colors.destructive,
            ),
            SizedBox(height: theme.spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.typography.base.copyWith(
                color: theme.colors.foreground,
              ),
            ),
            SizedBox(height: theme.spacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
