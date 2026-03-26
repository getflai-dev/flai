import 'package:flutter/material.dart';

class FlaiTypography {
  final String fontFamily;
  final String monoFontFamily;
  final double sm;
  final double base;
  final double lg;
  final double xl;
  final double xxl;
  final FontWeight regular;
  final FontWeight medium;
  final FontWeight semiBold;
  final FontWeight bold;

  const FlaiTypography({
    this.fontFamily = '.SF Pro Text',
    this.monoFontFamily = 'JetBrains Mono',
    this.sm = 12.0,
    this.base = 14.0,
    this.lg = 16.0,
    this.xl = 20.0,
    this.xxl = 24.0,
    this.regular = FontWeight.w400,
    this.medium = FontWeight.w500,
    this.semiBold = FontWeight.w600,
    this.bold = FontWeight.w700,
  });

  TextStyle bodySmall({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: sm,
    fontWeight: regular,
    color: color,
  );

  TextStyle bodyBase({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: base,
    fontWeight: regular,
    color: color,
  );

  TextStyle bodyLarge({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: lg,
    fontWeight: regular,
    color: color,
  );

  TextStyle heading({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: xl,
    fontWeight: semiBold,
    color: color,
  );

  TextStyle headingLarge({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: xxl,
    fontWeight: bold,
    color: color,
  );

  TextStyle mono({Color? color, double? fontSize}) => TextStyle(
    fontFamily: monoFontFamily,
    fontSize: fontSize ?? sm,
    fontWeight: regular,
    color: color,
  );

  FlaiTypography copyWith({
    String? fontFamily,
    String? monoFontFamily,
    double? sm,
    double? base,
    double? lg,
    double? xl,
    double? xxl,
    FontWeight? regular,
    FontWeight? medium,
    FontWeight? semiBold,
    FontWeight? bold,
  }) {
    return FlaiTypography(
      fontFamily: fontFamily ?? this.fontFamily,
      monoFontFamily: monoFontFamily ?? this.monoFontFamily,
      sm: sm ?? this.sm,
      base: base ?? this.base,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      regular: regular ?? this.regular,
      medium: medium ?? this.medium,
      semiBold: semiBold ?? this.semiBold,
      bold: bold ?? this.bold,
    );
  }
}
