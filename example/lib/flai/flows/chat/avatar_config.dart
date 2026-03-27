import 'package:flutter/material.dart';

import '../../core/theme/flai_theme.dart';

/// Configuration for an AI assistant avatar.
class AvatarConfig {
  /// An optional icon to display in the avatar.
  final IconData? icon;

  /// An optional gradient used as the avatar background.
  final List<Color>? gradient;

  /// A solid background color for the avatar (used when [gradient] is null).
  final Color? backgroundColor;

  /// The diameter of the avatar in logical pixels.
  final double size;

  /// The corner radius of the avatar container.
  final double borderRadius;

  /// An optional image to display as the avatar.
  final ImageProvider? image;

  /// An optional custom widget to render inside the avatar.
  final Widget? child;

  /// Creates an [AvatarConfig].
  const AvatarConfig({
    this.icon,
    this.gradient,
    this.backgroundColor,
    this.size = 40,
    this.borderRadius = 20,
    this.image,
    this.child,
  });
}

/// A widget that renders an assistant avatar based on [AvatarConfig].
///
/// Renders in the following priority order:
/// 1. [AvatarConfig.child] — fully custom widget
/// 2. [AvatarConfig.image] — image provider (e.g. NetworkImage)
/// 3. [AvatarConfig.icon] + [AvatarConfig.gradient] — icon over gradient
/// 4. [AvatarConfig.icon] + [AvatarConfig.backgroundColor] — icon over solid
/// 5. Default — `Icons.auto_awesome` over the theme primary color
class FlaiAvatar extends StatelessWidget {
  /// The avatar configuration.
  final AvatarConfig config;

  /// Override the size from [AvatarConfig.size].
  final double? sizeOverride;

  /// Creates a [FlaiAvatar].
  const FlaiAvatar({super.key, required this.config, this.sizeOverride});

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final size = sizeOverride ?? config.size;

    // Priority 1: fully custom child widget
    if (config.child != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(config.borderRadius),
        child: SizedBox(width: size, height: size, child: config.child),
      );
    }

    // Priority 2: image provider
    if (config.image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(config.borderRadius),
        child: Image(
          image: config.image!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    // Priority 3 & 4: icon (with gradient or solid background)
    // Priority 5: default icon + theme primary
    final icon = config.icon ?? Icons.auto_awesome;
    final iconSize = size * 0.5;

    final Widget iconWidget = Icon(
      icon,
      size: iconSize,
      color: config.gradient != null
          ? Colors.white
          : config.backgroundColor != null
          ? Colors.white
          : theme.colors.primaryForeground,
    );

    Widget background;

    if (config.gradient != null) {
      background = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: config.gradient!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
        child: Center(child: iconWidget),
      );
    } else {
      background = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: config.backgroundColor ?? theme.colors.primary,
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
        child: Center(child: iconWidget),
      );
    }

    return background;
  }
}
