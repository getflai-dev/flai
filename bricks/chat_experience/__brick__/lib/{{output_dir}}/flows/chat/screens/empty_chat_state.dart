import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../avatar_config.dart';
import '../chat_experience_config.dart';

/// The empty state shown when there are no messages in the chat.
///
/// Displays the assistant avatar, greeting, and subtitle centered on screen.
class FlaiEmptyChatState extends StatelessWidget {
  /// The chat experience configuration.
  final ChatExperienceConfig config;

  /// Creates a [FlaiEmptyChatState].
  const FlaiEmptyChatState({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlaiAvatar(
              config: config.assistantAvatar ?? const AvatarConfig(),
              sizeOverride: 64,
            ),
            SizedBox(height: theme.spacing.md),
            Text(
              config.resolvedGreeting,
              style: theme.typography.lg.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colors.foreground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: theme.spacing.xs),
            Text(
              config.resolvedGreetingSubtitle,
              style: theme.typography.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
