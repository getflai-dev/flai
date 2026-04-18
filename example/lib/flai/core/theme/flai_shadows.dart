import 'package:flutter/material.dart';

/// Elevation tokens for FlAI components.
///
/// FlAI prefers a borders-first depth strategy (Linear/Tesla/Apple): borders
/// describe shape, shadows describe lift. Shadows are intentionally subtle
/// — no large, blurry "Material" elevation.
///
/// * [none] — flat, borders only
/// * [xs]   — 1px hair-shadow for cards on a tinted backdrop
/// * [sm]   — small lift for popovers / floating chips
/// * [md]   — sheet / modal lift
/// * [lg]   — full-screen sheet drop
/// * [glow] — focus-ring style soft halo (use sparingly)
class FlaiShadows {
  final List<BoxShadow> none;
  final List<BoxShadow> xs;
  final List<BoxShadow> sm;
  final List<BoxShadow> md;
  final List<BoxShadow> lg;
  final List<BoxShadow> glow;

  const FlaiShadows({
    this.none = const <BoxShadow>[],
    this.xs = const <BoxShadow>[
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 1,
        offset: Offset(0, 1),
      ),
    ],
    this.sm = const <BoxShadow>[
      BoxShadow(
        color: Color(0x0F000000),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
    ],
    this.md = const <BoxShadow>[
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 6,
        offset: Offset(0, 4),
      ),
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
    this.lg = const <BoxShadow>[
      BoxShadow(
        color: Color(0x1F000000),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
    this.glow = const <BoxShadow>[
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 0,
        spreadRadius: 3,
      ),
    ],
  });

  /// Light preset — black-tinted shadows for paper-white surfaces.
  factory FlaiShadows.light() => const FlaiShadows();

  /// Dark preset — pure-black shadows under dark surfaces (lower opacity, larger
  /// blur — dark UIs need softer halos to read as elevation).
  factory FlaiShadows.dark() => const FlaiShadows(
    xs: <BoxShadow>[
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
    ],
    sm: <BoxShadow>[
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
    md: <BoxShadow>[
      BoxShadow(
        color: Color(0x4D000000),
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
    lg: <BoxShadow>[
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 32,
        offset: Offset(0, 16),
      ),
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
    glow: <BoxShadow>[
      BoxShadow(
        color: Color(0x33FFFFFF),
        blurRadius: 0,
        spreadRadius: 3,
      ),
    ],
  );

  FlaiShadows copyWith({
    List<BoxShadow>? none,
    List<BoxShadow>? xs,
    List<BoxShadow>? sm,
    List<BoxShadow>? md,
    List<BoxShadow>? lg,
    List<BoxShadow>? glow,
  }) {
    return FlaiShadows(
      none: none ?? this.none,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      glow: glow ?? this.glow,
    );
  }
}
