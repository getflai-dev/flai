import 'package:flutter/material.dart';

import 'flai_colors.dart';
import 'flai_icons.dart';
import 'flai_motion.dart';
import 'flai_radius.dart';
import 'flai_shadows.dart';
import 'flai_spacing.dart';
import 'flai_typography.dart';

class FlaiThemeData {
  final FlaiColors colors;
  final FlaiIconData icons;
  final FlaiTypography typography;
  final FlaiRadius radius;
  final FlaiSpacing spacing;
  final FlaiShadows shadows;
  final FlaiMotion motion;

  FlaiThemeData({
    required this.colors,
    FlaiIconData? icons,
    this.typography = const FlaiTypography(),
    this.radius = const FlaiRadius(),
    this.spacing = const FlaiSpacing(),
    FlaiShadows? shadows,
    this.motion = const FlaiMotion(),
  }) : icons = icons ?? FlaiIconData.material(),
       shadows = shadows ?? FlaiShadows.light();

  factory FlaiThemeData.light() => FlaiThemeData(
    colors: FlaiColors.light(),
    shadows: FlaiShadows.light(),
  );

  factory FlaiThemeData.dark() => FlaiThemeData(
    colors: FlaiColors.dark(),
    shadows: FlaiShadows.dark(),
  );

  factory FlaiThemeData.ios() => FlaiThemeData(
    colors: FlaiColors.ios(),
    icons: FlaiIconData.cupertino(),
    radius: const FlaiRadius(sm: 8, md: 12, lg: 18, xl: 22, xxl: 28, full: 9999),
    shadows: FlaiShadows.light(),
  );

  factory FlaiThemeData.premium() => FlaiThemeData(
    colors: FlaiColors.premium(),
    icons: FlaiIconData.sharp(),
    shadows: FlaiShadows.dark(),
  );

  /// `command` preset — generic Tesla / Apple / Linear aesthetic.
  ///
  /// * Pure neutrals, hairline borders (1px alpha-tinted), monochrome primary
  /// * SF Pro / SF Mono native stack
  /// * Tight tracking on headings, generous line-height on chat
  /// * Borders-first depth (subtle shadows)
  ///
  /// Override via [copyWith] to layer brand identity on top.
  factory FlaiThemeData.command() => FlaiThemeData(
    colors: FlaiColors.command(),
    icons: FlaiIconData.cupertino(),
    typography: const FlaiTypography(
      fontFamily: '.SF Pro Text',
      monoFontFamily: 'SF Mono',
      messageSize: 16,
      bodySize: 16,
    ),
    radius: const FlaiRadius(sm: 6, md: 10, lg: 14, xl: 18, xxl: 24, full: 9999),
    shadows: FlaiShadows.light(),
  );

  /// Inverted [FlaiThemeData.command] — true-black background, white primary.
  factory FlaiThemeData.commandDark() => FlaiThemeData(
    colors: FlaiColors.commandDark(),
    icons: FlaiIconData.cupertino(),
    typography: const FlaiTypography(
      fontFamily: '.SF Pro Text',
      monoFontFamily: 'SF Mono',
      messageSize: 16,
      bodySize: 16,
    ),
    radius: const FlaiRadius(sm: 6, md: 10, lg: 14, xl: 18, xxl: 24, full: 9999),
    shadows: FlaiShadows.dark(),
  );

  FlaiThemeData copyWith({
    FlaiColors? colors,
    FlaiIconData? icons,
    FlaiTypography? typography,
    FlaiRadius? radius,
    FlaiSpacing? spacing,
    FlaiShadows? shadows,
    FlaiMotion? motion,
  }) {
    return FlaiThemeData(
      colors: colors ?? this.colors,
      icons: icons ?? this.icons,
      typography: typography ?? this.typography,
      radius: radius ?? this.radius,
      spacing: spacing ?? this.spacing,
      shadows: shadows ?? this.shadows,
      motion: motion ?? this.motion,
    );
  }
}

class FlaiTheme extends InheritedWidget {
  final FlaiThemeData data;

  const FlaiTheme({super.key, required this.data, required super.child});

  static FlaiThemeData of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<FlaiTheme>();
    assert(
      widget != null,
      'No FlaiTheme found in context. Wrap your widget tree with FlaiTheme.',
    );
    return widget!.data;
  }

  static FlaiThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FlaiTheme>()?.data;
  }

  @override
  bool updateShouldNotify(FlaiTheme oldWidget) => data != oldWidget.data;
}
