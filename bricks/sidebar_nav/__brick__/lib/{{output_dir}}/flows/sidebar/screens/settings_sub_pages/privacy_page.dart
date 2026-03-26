import 'package:flutter/material.dart';

import '../../../../core/theme/flai_theme.dart';

/// A stub privacy settings page that developers can customize.
///
/// Displays data handling information and privacy toggle preferences.
class FlaiPrivacyPage extends StatefulWidget {
  /// Called when the user taps the back button.
  final VoidCallback onBack;

  /// Creates a [FlaiPrivacyPage].
  const FlaiPrivacyPage({super.key, required this.onBack});

  @override
  State<FlaiPrivacyPage> createState() => _FlaiPrivacyPageState();
}

class _FlaiPrivacyPageState extends State<FlaiPrivacyPage> {
  bool _shareUsageData = false;
  bool _personalizedSuggestions = false;

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
                'Privacy',
                style: theme.typography.lg.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(theme.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Data handling description
                Text(
                  'We take your privacy seriously. Your conversations are '
                  'encrypted in transit and at rest. You can control how your '
                  'data is used below. We will never sell your personal '
                  'information to third parties.',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: theme.spacing.lg),

                // Share usage data toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Share usage data',
                        style: theme.typography.base.copyWith(
                          color: theme.colors.foreground,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _shareUsageData,
                      onChanged: (v) => setState(() => _shareUsageData = v),
                      activeTrackColor: theme.colors.primary,
                    ),
                  ],
                ),
                SizedBox(height: theme.spacing.sm),

                // Personalized suggestions toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Personalized suggestions',
                        style: theme.typography.base.copyWith(
                          color: theme.colors.foreground,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _personalizedSuggestions,
                      onChanged: (v) =>
                          setState(() => _personalizedSuggestions = v),
                      activeTrackColor: theme.colors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
