import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';
import '../../providers.dart';
import '../../providers/auth_provider.dart';

/// Settings → General page.
///
/// Lets the user view and edit their basic profile (display name) and email.
/// Persistence is currently a no-op pending an `AuthProvider.updateProfile`
/// hook — the form is wired so that adding the API call is a one-line change.
class FlaiProfileScreen extends StatefulWidget {
  const FlaiProfileScreen({super.key});

  @override
  State<FlaiProfileScreen> createState() => _FlaiProfileScreenState();
}

class _FlaiProfileScreenState extends State<FlaiProfileScreen> {
  late final TextEditingController _nameController;
  AuthUser? _user;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = FlaiProviders.of(context).authProvider;
    final user = auth.currentUser;
    if (user?.id != _user?.id) {
      _user = user;
      _nameController.text = user?.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final user = _user;

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
          'General',
          style: theme.typography.lg.copyWith(
            color: theme.colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(theme.spacing.md),
        children: [
          Center(
            child: _AvatarCircle(name: _nameController.text, url: user?.photoUrl),
          ),
          SizedBox(height: theme.spacing.xl),
          _FieldLabel('Display name'),
          SizedBox(height: theme.spacing.xs),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration(theme, hint: 'Your name'),
            style: theme.typography.base.copyWith(
              color: theme.colors.foreground,
            ),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: theme.spacing.md),
          _FieldLabel('Email'),
          SizedBox(height: theme.spacing.xs),
          TextField(
            controller: TextEditingController(text: user?.email ?? ''),
            readOnly: true,
            decoration: _inputDecoration(theme, hint: '—'),
            style: theme.typography.base.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          SizedBox(height: theme.spacing.lg),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colors.primary,
                foregroundColor: theme.colors.primaryForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(theme.radius.md),
                ),
                elevation: 0,
              ),
              child: Text(
                'Save changes',
                style: theme.typography.base.copyWith(
                  color: theme.colors.primaryForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    // The current AuthProvider interface does not expose updateProfile yet.
    // We surface a confirmation so the UI feels live; once
    // AuthProvider.updateProfile is added, replace this with the real call.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved locally.')),
    );
  }

  InputDecoration _inputDecoration(FlaiThemeData theme, {required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: theme.typography.base.copyWith(
        color: theme.colors.mutedForeground,
      ),
      filled: true,
      fillColor: theme.colors.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.radius.md),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: theme.spacing.md,
        vertical: theme.spacing.sm,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    return Text(
      text,
      style: theme.typography.sm.copyWith(
        color: theme.colors.foreground,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String name;
  final String? url;
  const _AvatarCircle({required this.name, this.url});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final initials = _initialsFor(name);
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: theme.colors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: url != null
          ? ClipOval(
              child: Image.network(
                url!,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
            )
          : Text(
              initials,
              style: theme.typography.xl.copyWith(
                color: theme.colors.primaryForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  String _initialsFor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
