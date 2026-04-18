import 'package:flutter/material.dart';

/// CMMD brand identity tokens.
///
/// These are *brand* colors — they live outside [FlaiColors] because they
/// don't change between light and dark mode and they map to identity
/// (Nova, Autopilot, the ⌘ Command mark) rather than UI semantics.
///
/// Use them sparingly:
///   * [novaRose] — Nova assistant identity (avatar dot, badge text)
///   * [commandGreen] — the ⌘ wordmark and any "Command" surface
///   * [autopilotViolet] — Autopilot, scheduled actions, agentic state
///
/// Categories live in [CmmdBrandCategories] so the chat / sidebar can tag
/// data with consistent colors across the product.
@immutable
class CmmdBrand {
  // Identity
  final Color novaRose;
  final Color novaRoseSoft;
  final Color commandGreen;
  final Color commandGreenSoft;
  final Color autopilotViolet;
  final Color autopilotVioletSoft;

  // Ambient ink — used for the wordmark and headings to give a tiny tint
  // away from pure black (matches the cmmd.ai web tone).
  final Color ink;
  final Color paper;

  // Categories
  final CmmdBrandCategories categories;

  const CmmdBrand({
    this.novaRose = const Color(0xFFE11D48),
    this.novaRoseSoft = const Color(0xFFFFE4E6),
    this.commandGreen = const Color(0xFF16A34A),
    this.commandGreenSoft = const Color(0xFFDCFCE7),
    this.autopilotViolet = const Color(0xFF7C3AED),
    this.autopilotVioletSoft = const Color(0xFFEDE9FE),
    this.ink = const Color(0xFF0F0F10),
    this.paper = const Color(0xFFFFFFFF),
    this.categories = const CmmdBrandCategories(),
  });

  /// Dark-mode tuned variant — colors brightened so they stay legible
  /// against `commandDark` backgrounds.
  factory CmmdBrand.dark() => CmmdBrand(
    novaRose: const Color(0xFFFB7185),
    novaRoseSoft: const Color(0x33FB7185),
    commandGreen: const Color(0xFF4ADE80),
    commandGreenSoft: const Color(0x334ADE80),
    autopilotViolet: const Color(0xFFA78BFA),
    autopilotVioletSoft: const Color(0x33A78BFA),
    ink: const Color(0xFFFAFAFA),
    paper: const Color(0xFF000000),
    categories: CmmdBrandCategories.dark(),
  );

  CmmdBrand copyWith({
    Color? novaRose,
    Color? novaRoseSoft,
    Color? commandGreen,
    Color? commandGreenSoft,
    Color? autopilotViolet,
    Color? autopilotVioletSoft,
    Color? ink,
    Color? paper,
    CmmdBrandCategories? categories,
  }) {
    return CmmdBrand(
      novaRose: novaRose ?? this.novaRose,
      novaRoseSoft: novaRoseSoft ?? this.novaRoseSoft,
      commandGreen: commandGreen ?? this.commandGreen,
      commandGreenSoft: commandGreenSoft ?? this.commandGreenSoft,
      autopilotViolet: autopilotViolet ?? this.autopilotViolet,
      autopilotVioletSoft: autopilotVioletSoft ?? this.autopilotVioletSoft,
      ink: ink ?? this.ink,
      paper: paper ?? this.paper,
      categories: categories ?? this.categories,
    );
  }
}

/// Category color palette — used to tag conversations, contexts, and
/// connector data sources. Keep in sync with cmmd.ai web.
@immutable
class CmmdBrandCategories {
  final Color work; // blue
  final Color personal; // teal
  final Color finance; // amber
  final Color health; // rose
  final Color travel; // violet
  final Color learning; // emerald

  const CmmdBrandCategories({
    this.work = const Color(0xFF2563EB),
    this.personal = const Color(0xFF0D9488),
    this.finance = const Color(0xFFD97706),
    this.health = const Color(0xFFE11D48),
    this.travel = const Color(0xFF7C3AED),
    this.learning = const Color(0xFF059669),
  });

  /// Brightened variant for dark backgrounds.
  factory CmmdBrandCategories.dark() => const CmmdBrandCategories(
    work: Color(0xFF60A5FA),
    personal: Color(0xFF2DD4BF),
    finance: Color(0xFFFBBF24),
    health: Color(0xFFFB7185),
    travel: Color(0xFFA78BFA),
    learning: Color(0xFF34D399),
  );
}

/// Inherited widget exposing the active [CmmdBrand].
///
/// Wrap your app once near the root (typically alongside `FlaiTheme`) and
/// read brand tokens anywhere with `CmmdBrandTheme.of(context)`.
class CmmdBrandTheme extends InheritedWidget {
  final CmmdBrand brand;

  const CmmdBrandTheme({
    super.key,
    required this.brand,
    required super.child,
  });

  static CmmdBrand of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<CmmdBrandTheme>();
    assert(
      widget != null,
      'No CmmdBrandTheme found in context. Wrap your widget tree with CmmdBrandTheme.',
    );
    return widget!.brand;
  }

  static CmmdBrand? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CmmdBrandTheme>()?.brand;
  }

  @override
  bool updateShouldNotify(CmmdBrandTheme oldWidget) => brand != oldWidget.brand;
}
