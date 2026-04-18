/// Border-radius scale used across FlAI components.
///
/// Defaults follow the shadcn/ui scale (4 / 8 / 12 / 16). [xxl] (20) is added
/// for large message cards and the `command` aesthetic; [none] = 0 for sharp
/// edges on chrome and dividers.
class FlaiRadius {
  final double none;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double full;

  const FlaiRadius({
    this.none = 0.0,
    this.sm = 4.0,
    this.md = 8.0,
    this.lg = 12.0,
    this.xl = 16.0,
    this.xxl = 20.0,
    this.full = 9999.0,
  });

  FlaiRadius copyWith({
    double? none,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? full,
  }) {
    return FlaiRadius(
      none: none ?? this.none,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      full: full ?? this.full,
    );
  }
}
