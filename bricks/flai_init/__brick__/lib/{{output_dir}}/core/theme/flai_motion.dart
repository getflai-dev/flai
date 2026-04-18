import 'package:flutter/animation.dart';

/// Motion tokens — durations and curves shared across the system.
///
/// Curves are tuned to feel native on iOS while still reading as deliberate
/// on web/desktop. The defaults follow Apple's CASpringAnimation feel:
/// gentle deceleration for entrance, brisk for exit, no bounce on small UI.
class FlaiMotion {
  // Durations
  final Duration instant; // < 100ms — press feedback, ripple
  final Duration fast; // 150ms — hover, focus, color tween
  final Duration base; // 250ms — primary sheet / page
  final Duration slow; // 400ms — hero / reveal

  // Curves
  final Curve standard; // generic ease
  final Curve emphasized; // emphasized decel for entrance
  final Curve enter;
  final Curve exit;
  final Curve spring; // gentle spring (no overshoot)

  const FlaiMotion({
    this.instant = const Duration(milliseconds: 90),
    this.fast = const Duration(milliseconds: 150),
    this.base = const Duration(milliseconds: 250),
    this.slow = const Duration(milliseconds: 400),
    this.standard = Curves.easeInOut,
    this.emphasized = Curves.easeOutCubic,
    this.enter = Curves.easeOutCubic,
    this.exit = Curves.easeInCubic,
    this.spring = Curves.easeOutBack,
  });

  FlaiMotion copyWith({
    Duration? instant,
    Duration? fast,
    Duration? base,
    Duration? slow,
    Curve? standard,
    Curve? emphasized,
    Curve? enter,
    Curve? exit,
    Curve? spring,
  }) {
    return FlaiMotion(
      instant: instant ?? this.instant,
      fast: fast ?? this.fast,
      base: base ?? this.base,
      slow: slow ?? this.slow,
      standard: standard ?? this.standard,
      emphasized: emphasized ?? this.emphasized,
      enter: enter ?? this.enter,
      exit: exit ?? this.exit,
      spring: spring ?? this.spring,
    );
  }
}
