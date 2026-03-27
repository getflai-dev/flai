import 'package:flutter/material.dart';

import 'flai_colors.dart';
import 'flai_icons.dart';
import 'flai_typography.dart';
import 'flai_radius.dart';
import 'flai_spacing.dart';

class FlaiThemeData {
  final FlaiColors colors;
  final FlaiIconData icons;
  final FlaiTypography typography;
  final FlaiRadius radius;
  final FlaiSpacing spacing;

  FlaiThemeData({
    required this.colors,
    FlaiIconData? icons,
    this.typography = const FlaiTypography(),
    this.radius = const FlaiRadius(),
    this.spacing = const FlaiSpacing(),
  }) : icons = icons ?? FlaiIconData.material();

  factory FlaiThemeData.light() => FlaiThemeData(colors: FlaiColors.light());

  factory FlaiThemeData.dark() => FlaiThemeData(colors: FlaiColors.dark());

  factory FlaiThemeData.ios() => FlaiThemeData(
    colors: FlaiColors.ios(),
    icons: FlaiIconData.cupertino(),
    radius: const FlaiRadius(sm: 8, md: 12, lg: 18, xl: 22, full: 9999),
  );

  factory FlaiThemeData.premium() =>
      FlaiThemeData(colors: FlaiColors.premium(), icons: FlaiIconData.sharp());

  FlaiThemeData copyWith({
    FlaiColors? colors,
    FlaiIconData? icons,
    FlaiTypography? typography,
    FlaiRadius? radius,
    FlaiSpacing? spacing,
  }) {
    return FlaiThemeData(
      colors: colors ?? this.colors,
      icons: icons ?? this.icons,
      typography: typography ?? this.typography,
      radius: radius ?? this.radius,
      spacing: spacing ?? this.spacing,
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
