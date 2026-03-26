import 'package:flutter/material.dart';

import '../../../../core/theme/flai_theme.dart';

/// A stub connectors page that developers can customize.
///
/// Displays sample third-party service connector rows with connect buttons.
class FlaiConnectorsPage extends StatelessWidget {
  /// Called when the user taps the back button.
  final VoidCallback onBack;

  /// Creates a [FlaiConnectorsPage].
  const FlaiConnectorsPage({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    const connectors = [
      _ConnectorInfo(
        name: 'Google Drive',
        status: 'Not connected',
        icon: Icons.folder_rounded,
      ),
      _ConnectorInfo(
        name: 'Slack',
        status: 'Not connected',
        icon: Icons.chat_bubble_rounded,
      ),
      _ConnectorInfo(
        name: 'GitHub',
        status: 'Not connected',
        icon: Icons.code_rounded,
      ),
    ];

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
                onPressed: onBack,
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: theme.colors.foreground,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(width: theme.spacing.sm),
              Text(
                'Connectors',
                style: theme.typography.lg.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(theme.spacing.md),
            itemCount: connectors.length,
            separatorBuilder: (_, _) => SizedBox(height: theme.spacing.sm),
            itemBuilder: (_, index) {
              final connector = connectors[index];
              return Row(
                children: [
                  // Icon circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colors.muted,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      connector.icon,
                      size: 20,
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  SizedBox(width: theme.spacing.md),

                  // Name and status
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
                        Text(
                          connector.status,
                          style: theme.typography.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Connect button
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colors.foreground,
                      side: BorderSide(color: theme.colors.border, width: 1),
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
                      'Connect',
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.foreground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConnectorInfo {
  final String name;
  final String status;
  final IconData icon;

  const _ConnectorInfo({
    required this.name,
    required this.status,
    required this.icon,
  });
}
