import 'package:flutter/material.dart';

import '../../../../core/theme/flai_theme.dart';

/// A stub notifications settings page that developers can customize.
///
/// Displays toggle rows for push, email, and digest notification preferences.
class FlaiNotificationsPage extends StatefulWidget {
  /// Called when the user taps the back button.
  final VoidCallback onBack;

  /// Creates a [FlaiNotificationsPage].
  const FlaiNotificationsPage({super.key, required this.onBack});

  @override
  State<FlaiNotificationsPage> createState() => _FlaiNotificationsPageState();
}

class _FlaiNotificationsPageState extends State<FlaiNotificationsPage> {
  bool _pushNotifications = false;
  bool _emailUpdates = false;
  bool _weeklyDigest = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: theme.colors.foreground,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: theme.spacing.sm),
              Text(
                'Notifications',
                style: theme.typography.lg.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(theme.spacing.md),
            children: [
              _ToggleRow(
                label: 'Push notifications',
                value: _pushNotifications,
                onChanged: (v) => setState(() => _pushNotifications = v),
                theme: theme,
              ),
              SizedBox(height: theme.spacing.sm),
              _ToggleRow(
                label: 'Email updates',
                value: _emailUpdates,
                onChanged: (v) => setState(() => _emailUpdates = v),
                theme: theme,
              ),
              SizedBox(height: theme.spacing.sm),
              _ToggleRow(
                label: 'Weekly digest',
                value: _weeklyDigest,
                onChanged: (v) => setState(() => _weeklyDigest = v),
                theme: theme,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final dynamic theme;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.typography.base.copyWith(
            color: theme.colors.foreground,
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: theme.colors.primary,
        ),
      ],
    );
  }
}
