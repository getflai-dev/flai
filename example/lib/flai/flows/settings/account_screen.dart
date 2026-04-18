import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';
import '../../providers.dart';
import '../../providers/auth_provider.dart';

/// Settings → Account page.
///
/// Surfaces the active organization and any related identifiers. Switching
/// orgs is not implemented yet — this is a read-only summary that mirrors
/// the CMMD web "Account" panel.
class FlaiAccountScreen extends StatelessWidget {
  const FlaiAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final auth = FlaiProviders.of(context).authProvider;
    final user = auth.currentUser;
    final orgId = _readOrgId(auth);

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
          'Account',
          style: theme.typography.lg.copyWith(
            color: theme.colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: theme.spacing.sm),
        children: [
          _SectionHeader('Identity'),
          _Row(label: 'User ID', value: user?.id ?? '—'),
          _Row(label: 'Email', value: user?.email ?? '—'),
          if (user?.phoneNumber != null)
            _Row(label: 'Phone', value: user!.phoneNumber!),
          Divider(color: theme.colors.border, height: 1),
          _SectionHeader('Workspace'),
          _Row(label: 'Active organization', value: orgId ?? 'Personal'),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
            leading: Icon(
              Icons.swap_horiz_rounded,
              color: theme.colors.foreground,
              size: 20,
            ),
            title: Text(
              'Switch workspace',
              style: theme.typography.base.copyWith(
                color: theme.colors.foreground,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: theme.colors.mutedForeground,
              size: 20,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Workspace switching is coming soon.'),
                ),
              );
            },
          ),
          Divider(color: theme.colors.border, height: 1),
          _SectionHeader('Session'),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: theme.spacing.md),
            leading: Icon(Icons.logout_rounded, color: theme.colors.destructive, size: 20),
            title: Text(
              'Sign out',
              style: theme.typography.base.copyWith(
                color: theme.colors.destructive,
              ),
            ),
            onTap: () => auth.signOut(),
          ),
        ],
      ),
    );
  }

  /// Reads `organizationId` from the auth provider via dynamic lookup so we
  /// don't have to depend on the CMMD-specific subclass from this file.
  String? _readOrgId(AuthProvider auth) {
    try {
      final dyn = auth as dynamic;
      final value = dyn.organizationId;
      if (value is String && value.isNotEmpty) return value;
    } catch (_) {}
    return null;
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

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.md,
        vertical: theme.spacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.typography.base.copyWith(
              color: theme.colors.foreground,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.base.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
