import 'package:flutter/material.dart';

import '../core/theme/flai_radius.dart';
import '../core/theme/flai_shadows.dart';
import '../core/theme/flai_theme.dart';
import '../core/theme/flai_typography.dart';

/// CMMD-tuned [FlaiThemeData] presets.
///
/// Builds on top of [FlaiThemeData.command] / [FlaiThemeData.commandDark]
/// and overlays CMMD-specific tweaks:
///
/// * Slightly warmer ink (`#0F0F10` instead of `#171717`) for the
///   wordmark / headings to match cmmd.ai web.
/// * A whisper-warm paper backdrop (`#FAFAFA` for secondary surfaces).
/// * Card radius bumped to 14 / 18 so message cards feel like the
///   web "messages" cards.
/// * Slightly heavier hairline border (`borderSubtle` at 8% black)
///   because mobile pixel density makes 5% disappear.
///
/// Brand identity (rose Nova, green ⌘, violet Autopilot) lives in
/// `CmmdBrand` — read it via `CmmdBrandTheme.of(context)`. We deliberately
/// keep brand colors out of `FlaiColors` so theme swaps don't disturb them.
class CmmdTheme {
  CmmdTheme._();

  /// CMMD light — paper-white surfaces, deep ink text, hairline borders.
  /// This is the default for the CMMD mobile MVP.
  static FlaiThemeData light() {
    final base = FlaiThemeData.command();
    return base.copyWith(
      colors: base.colors.copyWith(
        // Warmer ink for headings / wordmark
        foreground: const Color(0xFF0F0F10),
        cardForeground: const Color(0xFF0F0F10),
        popoverForeground: const Color(0xFF0F0F10),
        primary: const Color(0xFF0F0F10),
        // Slightly warmer paper for the second tier
        surfaceSecondary: const Color(0xFFFAFAFA),
        // Warm hairline borders (matches cmmd.ai)
        border: const Color(0x14000000),
        borderSubtle: const Color(0x0F000000),
        // Outline-style assistant bubble: white card on warm paper
        assistantBubble: const Color(0xFFFFFFFF),
        assistantBubbleForeground: const Color(0xFF0F0F10),
      ),
      radius: const FlaiRadius(
        sm: 6,
        md: 10,
        lg: 14,
        xl: 18,
        xxl: 24,
        full: 9999,
      ),
      typography: const FlaiTypography(
        fontFamily: '.SF Pro Text',
        monoFontFamily: 'SF Mono',
        messageSize: 16,
        bodySize: 16,
      ),
      shadows: FlaiShadows.light(),
    );
  }

  /// CMMD dark — true-black backdrop, white primary, hairline white borders.
  static FlaiThemeData dark() {
    final base = FlaiThemeData.commandDark();
    return base.copyWith(
      colors: base.colors.copyWith(
        primary: const Color(0xFFFFFFFF),
        surfaceSecondary: const Color(0xFF0A0A0A),
        border: const Color(0x1AFFFFFF),
        borderSubtle: const Color(0x14FFFFFF),
        assistantBubble: const Color(0xFF0A0A0A),
        assistantBubbleForeground: const Color(0xFFFFFFFF),
      ),
      radius: const FlaiRadius(
        sm: 6,
        md: 10,
        lg: 14,
        xl: 18,
        xxl: 24,
        full: 9999,
      ),
      typography: const FlaiTypography(
        fontFamily: '.SF Pro Text',
        monoFontFamily: 'SF Mono',
        messageSize: 16,
        bodySize: 16,
      ),
      shadows: FlaiShadows.dark(),
    );
  }
}
