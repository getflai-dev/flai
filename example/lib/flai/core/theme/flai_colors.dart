import 'package:flutter/material.dart';

/// Color tokens for FlAI components.
///
/// Tokens are organised in tiers so themes can express depth and hierarchy
/// without inventing one-off colors per widget:
///
/// * **Surfaces** — `background`, `surfaceSecondary`, `surfaceTertiary`,
///   `surfaceElevated` — backdrop and card backgrounds, ordered from
///   the deepest layer outward.
/// * **Text** — `foreground`, `mutedForeground`, `textTertiary`,
///   `textPlaceholder` — primary content down to placeholder text.
/// * **Borders** — `border`, `borderSubtle`, `borderStrong` — three weights
///   for separators, dividers, and emphasis edges.
/// * **Status** — `destructive`, `success`, `warning`, `info` — semantic
///   colors that always mean the same thing across the product.
///
/// All optional fields fall back to sensible **light-theme** defaults so
/// existing code keeps compiling. Dark/non-light presets should override
/// every optional field explicitly.
class FlaiColors {
  // ── Surfaces ──────────────────────────────────────────────────────────
  final Color background;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color surfaceElevated;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;

  // ── Text ──────────────────────────────────────────────────────────────
  final Color foreground;
  final Color mutedForeground;
  final Color textTertiary;
  final Color textPlaceholder;

  // ── Brand / accent ────────────────────────────────────────────────────
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color accent;
  final Color accentForeground;

  // ── Borders ───────────────────────────────────────────────────────────
  final Color border;
  final Color borderSubtle;
  final Color borderStrong;
  final Color input;
  final Color ring;

  // ── Status ────────────────────────────────────────────────────────────
  final Color destructive;
  final Color destructiveForeground;
  final Color success;
  final Color warning;
  final Color info;

  // ── Chat bubbles ──────────────────────────────────────────────────────
  final Color userBubble;
  final Color userBubbleForeground;
  final Color assistantBubble;
  final Color assistantBubbleForeground;

  const FlaiColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.userBubble,
    required this.userBubbleForeground,
    required this.assistantBubble,
    required this.assistantBubbleForeground,
    // Optional tiers (light defaults; dark presets override)
    this.surfaceSecondary = const Color(0xFFFAFAFA),
    this.surfaceTertiary = const Color(0xFFF5F5F5),
    this.surfaceElevated = const Color(0xFFFFFFFF),
    this.textTertiary = const Color(0xFF737373),
    this.textPlaceholder = const Color(0xFFD4D4D4),
    this.borderSubtle = const Color(0x0D000000),
    this.borderStrong = const Color(0x26000000),
    this.success = const Color(0xFF16A34A),
    this.warning = const Color(0xFFF59E0B),
    this.info = const Color(0xFF0EA5E9),
  });

  /// Zinc light preset
  factory FlaiColors.light() => const FlaiColors(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF09090B),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF09090B),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF09090B),
    primary: Color(0xFF18181B),
    primaryForeground: Color(0xFFFAFAFA),
    secondary: Color(0xFFF4F4F5),
    secondaryForeground: Color(0xFF18181B),
    muted: Color(0xFFF4F4F5),
    mutedForeground: Color(0xFF71717A),
    accent: Color(0xFFF4F4F5),
    accentForeground: Color(0xFF18181B),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFFAFAFA),
    border: Color(0xFFE4E4E7),
    input: Color(0xFFE4E4E7),
    ring: Color(0xFF18181B),
    userBubble: Color(0xFF18181B),
    userBubbleForeground: Color(0xFFFAFAFA),
    assistantBubble: Color(0xFFF4F4F5),
    assistantBubbleForeground: Color(0xFF09090B),
  );

  /// Zinc dark preset
  factory FlaiColors.dark() => const FlaiColors(
    background: Color(0xFF09090B),
    foreground: Color(0xFFFAFAFA),
    card: Color(0xFF09090B),
    cardForeground: Color(0xFFFAFAFA),
    popover: Color(0xFF09090B),
    popoverForeground: Color(0xFFFAFAFA),
    primary: Color(0xFFFAFAFA),
    primaryForeground: Color(0xFF18181B),
    secondary: Color(0xFF27272A),
    secondaryForeground: Color(0xFFFAFAFA),
    muted: Color(0xFF27272A),
    mutedForeground: Color(0xFFA1A1AA),
    accent: Color(0xFF27272A),
    accentForeground: Color(0xFFFAFAFA),
    destructive: Color(0xFF7F1D1D),
    destructiveForeground: Color(0xFFFAFAFA),
    border: Color(0xFF27272A),
    input: Color(0xFF27272A),
    ring: Color(0xFFD4D4D8),
    userBubble: Color(0xFFFAFAFA),
    userBubbleForeground: Color(0xFF18181B),
    assistantBubble: Color(0xFF27272A),
    assistantBubbleForeground: Color(0xFFFAFAFA),
    surfaceSecondary: Color(0xFF18181B),
    surfaceTertiary: Color(0xFF27272A),
    surfaceElevated: Color(0xFF18181B),
    textTertiary: Color(0xFF71717A),
    textPlaceholder: Color(0xFF52525B),
    borderSubtle: Color(0x0DFFFFFF),
    borderStrong: Color(0x33FFFFFF),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF38BDF8),
  );

  /// iOS Apple Messages preset
  factory FlaiColors.ios() => const FlaiColors(
    background: Color(0xFFF2F2F7),
    foreground: Color(0xFF000000),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF000000),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF000000),
    primary: Color(0xFF007AFF),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFE5E5EA),
    secondaryForeground: Color(0xFF000000),
    muted: Color(0xFFE5E5EA),
    mutedForeground: Color(0xFF8E8E93),
    accent: Color(0xFF007AFF),
    accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFFFF3B30),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFFD1D1D6),
    input: Color(0xFFD1D1D6),
    ring: Color(0xFF007AFF),
    userBubble: Color(0xFF007AFF),
    userBubbleForeground: Color(0xFFFFFFFF),
    assistantBubble: Color(0xFFE5E5EA),
    assistantBubbleForeground: Color(0xFF000000),
    surfaceSecondary: Color(0xFFFFFFFF),
    surfaceTertiary: Color(0xFFF2F2F7),
    surfaceElevated: Color(0xFFFFFFFF),
    textTertiary: Color(0xFF8E8E93),
    textPlaceholder: Color(0xFFC7C7CC),
    borderSubtle: Color(0x14000000),
    borderStrong: Color(0x33000000),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9500),
    info: Color(0xFF007AFF),
  );

  /// Premium dark preset (Linear-inspired)
  factory FlaiColors.premium() => const FlaiColors(
    background: Color(0xFF0A0A0F),
    foreground: Color(0xFFEEEEF0),
    card: Color(0xFF12121A),
    cardForeground: Color(0xFFEEEEF0),
    popover: Color(0xFF12121A),
    popoverForeground: Color(0xFFEEEEF0),
    primary: Color(0xFF818CF8),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF1E1E2E),
    secondaryForeground: Color(0xFFEEEEF0),
    muted: Color(0xFF1E1E2E),
    mutedForeground: Color(0xFF71717A),
    accent: Color(0xFF6366F1),
    accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFF1E1E2E),
    input: Color(0xFF1E1E2E),
    ring: Color(0xFF818CF8),
    userBubble: Color(0xFF6366F1),
    userBubbleForeground: Color(0xFFFFFFFF),
    assistantBubble: Color(0xFF1E1E2E),
    assistantBubbleForeground: Color(0xFFEEEEF0),
    surfaceSecondary: Color(0xFF12121A),
    surfaceTertiary: Color(0xFF1E1E2E),
    surfaceElevated: Color(0xFF1E1E2E),
    textTertiary: Color(0xFF8B8B95),
    textPlaceholder: Color(0xFF52525B),
    borderSubtle: Color(0x14FFFFFF),
    borderStrong: Color(0x33FFFFFF),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF38BDF8),
  );

  /// `command` preset — generic Tesla / Apple / Linear aesthetic.
  ///
  /// Pure neutrals, hairline borders, monochrome primary, color reserved
  /// for status and meaning only. Use [FlaiColors.commandDark] for the
  /// inverted variant.
  factory FlaiColors.command() => const FlaiColors(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF171717),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF171717),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF171717),
    primary: Color(0xFF171717),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFF5F5F5),
    secondaryForeground: Color(0xFF171717),
    muted: Color(0xFFF5F5F5),
    mutedForeground: Color(0xFF525252),
    accent: Color(0xFF171717),
    accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFFDC2626),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0x14000000),
    input: Color(0x14000000),
    ring: Color(0x80000000),
    userBubble: Color(0xFF171717),
    userBubbleForeground: Color(0xFFFFFFFF),
    assistantBubble: Color(0xFFFFFFFF),
    assistantBubbleForeground: Color(0xFF171717),
    surfaceSecondary: Color(0xFFFAFAFA),
    surfaceTertiary: Color(0xFFF5F5F5),
    surfaceElevated: Color(0xFFFFFFFF),
    textTertiary: Color(0xFF737373),
    textPlaceholder: Color(0xFFD4D4D4),
    borderSubtle: Color(0x0D000000),
    borderStrong: Color(0x26000000),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF0EA5E9),
  );

  /// `commandDark` preset — inverted [FlaiColors.command]. Tesla true-black,
  /// hairline white borders, monochrome primary, status colors brightened
  /// for dark backgrounds.
  factory FlaiColors.commandDark() => const FlaiColors(
    background: Color(0xFF000000),
    foreground: Color(0xFFFFFFFF),
    card: Color(0xFF0A0A0A),
    cardForeground: Color(0xFFFFFFFF),
    popover: Color(0xFF1C1C1E),
    popoverForeground: Color(0xFFFFFFFF),
    primary: Color(0xFFFFFFFF),
    primaryForeground: Color(0xFF000000),
    secondary: Color(0xFF262626),
    secondaryForeground: Color(0xFFFFFFFF),
    muted: Color(0xFF141414),
    mutedForeground: Color(0xFFA3A3A3),
    accent: Color(0xFFFFFFFF),
    accentForeground: Color(0xFF000000),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0x1AFFFFFF),
    input: Color(0x1AFFFFFF),
    ring: Color(0x80FFFFFF),
    userBubble: Color(0xFFFFFFFF),
    userBubbleForeground: Color(0xFF000000),
    assistantBubble: Color(0xFF0A0A0A),
    assistantBubbleForeground: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFF0A0A0A),
    surfaceTertiary: Color(0xFF141414),
    surfaceElevated: Color(0xFF1C1C1E),
    textTertiary: Color(0xFF737373),
    textPlaceholder: Color(0xFF404040),
    borderSubtle: Color(0x0DFFFFFF),
    borderStrong: Color(0x33FFFFFF),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF38BDF8),
  );

  FlaiColors copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? popover,
    Color? popoverForeground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? userBubble,
    Color? userBubbleForeground,
    Color? assistantBubble,
    Color? assistantBubbleForeground,
    Color? surfaceSecondary,
    Color? surfaceTertiary,
    Color? surfaceElevated,
    Color? textTertiary,
    Color? textPlaceholder,
    Color? borderSubtle,
    Color? borderStrong,
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return FlaiColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      popover: popover ?? this.popover,
      popoverForeground: popoverForeground ?? this.popoverForeground,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      userBubble: userBubble ?? this.userBubble,
      userBubbleForeground: userBubbleForeground ?? this.userBubbleForeground,
      assistantBubble: assistantBubble ?? this.assistantBubble,
      assistantBubbleForeground:
          assistantBubbleForeground ?? this.assistantBubbleForeground,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceTertiary: surfaceTertiary ?? this.surfaceTertiary,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textTertiary: textTertiary ?? this.textTertiary,
      textPlaceholder: textPlaceholder ?? this.textPlaceholder,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }
}
