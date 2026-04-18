import 'package:flutter/material.dart';

import 'cmmd_brand.dart';

/// CMMD wordmark — the green Apple ⌘ command symbol followed by the
/// "CMMD" text.
///
/// Pulls colours from [CmmdBrandTheme]; falls back to [CmmdBrand]
/// defaults if no `CmmdBrandTheme` ancestor is found.
///
/// Variants:
///   * [CmmdLogo.mark] — the ⌘ glyph alone (use when space is tight)
///   * [CmmdLogo.full] — ⌘ + CMMD wordmark inline
///   * [CmmdLogo.stack] — ⌘ tile (square, filled) above wordmark
class CmmdLogo extends StatelessWidget {
  /// Pixel size of the ⌘ glyph. Default 22.
  final double glyphSize;

  /// Whether to render the "CMMD" wordmark next to the glyph.
  final bool showWordmark;

  /// Optional override for the wordmark color. Defaults to the surrounding
  /// `DefaultTextStyle` color, which usually inherits from `FlaiColors.foreground`.
  final Color? wordmarkColor;

  /// Optional override for the ⌘ glyph color. Defaults to
  /// `CmmdBrand.commandGreen`.
  final Color? glyphColor;

  const CmmdLogo({
    super.key,
    this.glyphSize = 22,
    this.showWordmark = true,
    this.wordmarkColor,
    this.glyphColor,
  });

  /// The ⌘ mark only — square tile suitable for app icons or tight chrome.
  const CmmdLogo.mark({super.key, this.glyphSize = 22, this.glyphColor})
    : showWordmark = false,
      wordmarkColor = null;

  /// The full ⌘ + CMMD wordmark, sized for top-nav usage (22pt glyph).
  const CmmdLogo.full({
    super.key,
    this.glyphSize = 22,
    this.glyphColor,
    this.wordmarkColor,
  }) : showWordmark = true;

  @override
  Widget build(BuildContext context) {
    final brand = CmmdBrandTheme.maybeOf(context) ?? const CmmdBrand();
    final resolvedGlyph = glyphColor ?? brand.commandGreen;

    final glyph = Text(
      '\u2318', // ⌘
      style: TextStyle(
        fontSize: glyphSize,
        fontWeight: FontWeight.w600,
        color: resolvedGlyph,
        height: 1,
        letterSpacing: 0,
      ),
    );

    if (!showWordmark) return glyph;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        glyph,
        SizedBox(width: glyphSize * 0.36),
        Text(
          'CMMD',
          style: TextStyle(
            fontSize: glyphSize * 0.78,
            fontWeight: FontWeight.w700,
            color: wordmarkColor,
            letterSpacing: -0.2,
            height: 1,
          ),
        ),
      ],
    );
  }
}
