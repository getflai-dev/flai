import 'package:flutter/material.dart';

class FlaiColors {
  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;
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
    );
  }
}
