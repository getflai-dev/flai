import 'package:flutter/material.dart';

/// Type scale and font tokens for FlAI.
///
/// Adds letter-spacing tokens and dedicated chat sizes so the chat surface
/// can tune density independently from headings. Defaults assume an Apple
/// system stack (`.SF Pro Text` body, `SF Mono` monospace).
class FlaiTypography {
  final String fontFamily;
  final String monoFontFamily;
  final List<String> fontFamilyFallback;

  // Sizes
  final double smSize;
  final double baseSize;
  final double lgSize;
  final double xlSize;
  final double xxlSize;

  // Chat-specific (overridable independently of body sizes)
  final double messageSize; // chat bubble body
  final double bodySize; // long-form prose

  // Weights
  final FontWeight regular;
  final FontWeight medium;
  final FontWeight semiBold;
  final FontWeight bold;

  // Tracking (letter-spacing) — Apple/Linear use very tight tracking on
  // headings and slightly loose on small caps / labels.
  final double trackingTight;
  final double trackingNormal;
  final double trackingWide;

  const FlaiTypography({
    this.fontFamily = '.SF Pro Text',
    this.monoFontFamily = 'SF Mono',
    this.fontFamilyFallback = const <String>[
      '.SF Pro Text',
      '-apple-system',
      'BlinkMacSystemFont',
      'Inter',
      'Helvetica Neue',
      'Arial',
    ],
    this.smSize = 13.0,
    this.baseSize = 16.0,
    this.lgSize = 17.0,
    this.xlSize = 20.0,
    this.xxlSize = 24.0,
    this.messageSize = 16.0,
    this.bodySize = 16.0,
    this.regular = FontWeight.w400,
    this.medium = FontWeight.w500,
    this.semiBold = FontWeight.w600,
    this.bold = FontWeight.w700,
    this.trackingTight = -0.4,
    this.trackingNormal = 0.0,
    this.trackingWide = 0.4,
  });

  // Shadcn-style TextStyle getters (short names for convenience)

  /// Body small text style (13pt — iOS Footnote).
  TextStyle get sm => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: smSize,
    fontWeight: regular,
  );

  /// Body base text style (16pt — iOS Callout).
  TextStyle get base => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: baseSize,
    fontWeight: regular,
  );

  /// Body large text style (17pt — iOS Body).
  TextStyle get lg => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: lgSize,
    fontWeight: regular,
  );

  /// Heading text style (20pt, semi-bold).
  TextStyle get xl => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: xlSize,
    fontWeight: semiBold,
    letterSpacing: trackingTight,
  );

  /// Large heading text style (24pt, bold).
  TextStyle get xxl => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: xxlSize,
    fontWeight: bold,
    letterSpacing: trackingTight,
  );

  /// Chat-message body style.
  TextStyle get message => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: messageSize,
    fontWeight: regular,
    height: 1.45,
    letterSpacing: -0.1,
  );

  /// Long-form prose body style.
  TextStyle get body => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: bodySize,
    fontWeight: regular,
    height: 1.6,
  );

  /// Eyebrow / micro-label (uppercase, tight, wide tracking).
  TextStyle get eyebrow => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 11,
    fontWeight: semiBold,
    letterSpacing: trackingWide,
    height: 1.2,
  );

  // Verbose method aliases (for backward compatibility)

  TextStyle bodySmall({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: smSize,
    fontWeight: regular,
    color: color,
  );

  TextStyle bodyBase({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: baseSize,
    fontWeight: regular,
    color: color,
  );

  TextStyle bodyLarge({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: lgSize,
    fontWeight: regular,
    color: color,
  );

  TextStyle heading({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: xlSize,
    fontWeight: semiBold,
    letterSpacing: trackingTight,
    color: color,
  );

  TextStyle headingLarge({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: xxlSize,
    fontWeight: bold,
    letterSpacing: trackingTight,
    color: color,
  );

  TextStyle mono({Color? color, double? fontSize}) => TextStyle(
    fontFamily: monoFontFamily,
    fontSize: fontSize ?? smSize,
    fontWeight: regular,
    color: color,
  );

  FlaiTypography copyWith({
    String? fontFamily,
    String? monoFontFamily,
    List<String>? fontFamilyFallback,
    double? smSize,
    double? baseSize,
    double? lgSize,
    double? xlSize,
    double? xxlSize,
    double? messageSize,
    double? bodySize,
    FontWeight? regular,
    FontWeight? medium,
    FontWeight? semiBold,
    FontWeight? bold,
    double? trackingTight,
    double? trackingNormal,
    double? trackingWide,
  }) {
    return FlaiTypography(
      fontFamily: fontFamily ?? this.fontFamily,
      monoFontFamily: monoFontFamily ?? this.monoFontFamily,
      fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
      smSize: smSize ?? this.smSize,
      baseSize: baseSize ?? this.baseSize,
      lgSize: lgSize ?? this.lgSize,
      xlSize: xlSize ?? this.xlSize,
      xxlSize: xxlSize ?? this.xxlSize,
      messageSize: messageSize ?? this.messageSize,
      bodySize: bodySize ?? this.bodySize,
      regular: regular ?? this.regular,
      medium: medium ?? this.medium,
      semiBold: semiBold ?? this.semiBold,
      bold: bold ?? this.bold,
      trackingTight: trackingTight ?? this.trackingTight,
      trackingNormal: trackingNormal ?? this.trackingNormal,
      trackingWide: trackingWide ?? this.trackingWide,
    );
  }
}
