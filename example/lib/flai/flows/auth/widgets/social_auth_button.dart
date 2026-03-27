import 'package:flutter/material.dart';

import '../../../core/theme/flai_theme.dart';
import '../auth_flow_config.dart';

/// Styled button for social authentication (Apple, Google, Microsoft, Phone).
///
/// Apple, Google, and Microsoft buttons use custom-painted brand logos
/// that match each company's brand guidelines. Phone uses a Material icon.
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.type,
    required this.onTap,
    this.isLoading = false,
  });

  final SocialAuthType type;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = FlaiTheme.of(context);
    final isPrimary = type == SocialAuthType.apple;
    final fgColor = isPrimary
        ? theme.colors.background
        : theme.colors.foreground;

    final (label, logo) = switch (type) {
      SocialAuthType.apple => (
        'Continue with Apple',
        _AppleLogo(color: fgColor),
      ),
      SocialAuthType.google => ('Continue with Google', const _GoogleLogo()),
      SocialAuthType.microsoft => (
        'Continue with Microsoft',
        const _MicrosoftLogo(),
      ),
      SocialAuthType.phone => (
        'Continue with phone',
        Icon(Icons.phone, size: 20, color: fgColor) as Widget,
      ),
    };

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: isLoading ? null : onTap,
        style: TextButton.styleFrom(
          backgroundColor: isPrimary
              ? theme.colors.foreground
              : Colors.transparent,
          foregroundColor: fgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radius.full),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: theme.colors.border),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fgColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20, height: 20, child: logo),
                  const SizedBox(width: 10),
                  Text(label, style: theme.typography.base),
                ],
              ),
      ),
    );
  }
}

// ── Apple Logo ──────────────────────────────────────────────────────────────

/// Apple logo drawn via CustomPaint using the standard apple shape path.
class _AppleLogo extends StatelessWidget {
  const _AppleLogo({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AppleLogoPainter(color: color));
  }
}

class _AppleLogoPainter extends CustomPainter {
  _AppleLogoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Simplified Apple logo path scaled to the given size.
    final path = Path()
      // Apple body
      ..moveTo(w * 0.83, h * 0.34)
      ..cubicTo(w * 0.82, h * 0.34, w * 0.70, h * 0.26, w * 0.60, h * 0.26)
      ..cubicTo(w * 0.44, h * 0.26, w * 0.35, h * 0.35, w * 0.29, h * 0.35)
      ..cubicTo(w * 0.22, h * 0.35, w * 0.13, h * 0.27, w * 0.04, h * 0.27)
      ..cubicTo(w * -0.11, h * 0.27, w * -0.08, h * 0.55, w * 0.10, h * 0.80)
      ..cubicTo(w * 0.18, h * 0.90, w * 0.27, h * 1.02, w * 0.39, h * 1.02)
      ..cubicTo(w * 0.49, h * 1.01, w * 0.52, h * 0.95, w * 0.62, h * 0.95)
      ..cubicTo(w * 0.72, h * 0.95, w * 0.74, h * 1.01, w * 0.85, h * 1.01)
      ..cubicTo(w * 0.97, h * 1.01, w * 1.05, h * 0.88, w * 1.12, h * 0.78)
      ..cubicTo(w * 1.17, h * 0.71, w * 1.18, h * 0.68, w * 1.20, h * 0.62)
      ..cubicTo(w * 0.97, h * 0.52, w * 0.93, h * 0.20, w * 1.17, h * 0.06)
      ..cubicTo(w * 1.08, h * -0.06, w * 0.96, h * -0.13, w * 0.83, h * -0.12)
      ..cubicTo(w * 0.72, h * -0.12, w * 0.62, h * -0.05, w * 0.57, h * -0.05)
      ..cubicTo(w * 0.51, h * -0.05, w * 0.42, h * -0.12, w * 0.31, h * -0.12)
      ..cubicTo(w * 0.22, h * -0.12, w * 0.09, h * -0.07, w * 0.02, h * 0.04)
      ..cubicTo(w * -0.09, h * 0.22, w * -0.05, h * 0.53, w * 0.10, h * 0.80)
      ..close();

    // Scale and center
    canvas.save();
    canvas.translate(w * 0.05, h * 0.07);
    canvas.scale(0.9, 0.9);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AppleLogoPainter oldDelegate) =>
      color != oldDelegate.color;
}

// ── Google Logo ─────────────────────────────────────────────────────────────

/// Google "G" logo with the four brand colors, drawn from the official SVG path.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24;

    // Blue arc
    final bluePath = Path()
      ..moveTo(22.56 * s, 12.25 * s)
      ..cubicTo(22.56 * s, 11.47 * s, 22.49 * s, 10.72 * s, 22.36 * s, 10 * s)
      ..lineTo(12 * s, 10 * s)
      ..lineTo(12 * s, 14.26 * s)
      ..lineTo(17.92 * s, 14.26 * s)
      ..cubicTo(
        17.66 * s,
        15.63 * s,
        16.89 * s,
        16.79 * s,
        15.72 * s,
        17.58 * s,
      )
      ..lineTo(15.72 * s, 20.35 * s)
      ..lineTo(19.28 * s, 20.35 * s)
      ..cubicTo(
        21.36 * s,
        18.43 * s,
        22.56 * s,
        15.61 * s,
        22.56 * s,
        12.25 * s,
      )
      ..close();
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4));

    // Green arc
    final greenPath = Path()
      ..moveTo(12 * s, 23 * s)
      ..cubicTo(14.97 * s, 23 * s, 17.46 * s, 22.02 * s, 19.28 * s, 20.34 * s)
      ..lineTo(15.72 * s, 17.58 * s)
      ..cubicTo(14.74 * s, 18.24 * s, 13.49 * s, 18.64 * s, 12 * s, 18.64 * s)
      ..cubicTo(9.14 * s, 18.64 * s, 6.71 * s, 16.71 * s, 5.84 * s, 14.11 * s)
      ..lineTo(2.18 * s, 14.11 * s)
      ..lineTo(2.18 * s, 16.95 * s)
      ..cubicTo(3.99 * s, 20.53 * s, 7.7 * s, 23 * s, 12 * s, 23 * s)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853));

    // Yellow arc
    final yellowPath = Path()
      ..moveTo(5.84 * s, 14.09 * s)
      ..cubicTo(5.62 * s, 13.43 * s, 5.49 * s, 12.73 * s, 5.49 * s, 12 * s)
      ..cubicTo(5.49 * s, 11.27 * s, 5.62 * s, 10.57 * s, 5.84 * s, 9.91 * s)
      ..lineTo(5.84 * s, 7.07 * s)
      ..lineTo(2.18 * s, 7.07 * s)
      ..cubicTo(1.43 * s, 8.55 * s, 1 * s, 10.22 * s, 1 * s, 12 * s)
      ..cubicTo(1 * s, 13.78 * s, 1.43 * s, 15.45 * s, 2.18 * s, 16.93 * s)
      ..lineTo(5.84 * s, 14.09 * s)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05));

    // Red arc
    final redPath = Path()
      ..moveTo(12 * s, 5.38 * s)
      ..cubicTo(13.62 * s, 5.38 * s, 15.06 * s, 5.94 * s, 16.21 * s, 7.02 * s)
      ..lineTo(19.36 * s, 3.87 * s)
      ..cubicTo(17.45 * s, 2.09 * s, 14.97 * s, 1 * s, 12 * s, 1 * s)
      ..cubicTo(7.7 * s, 1 * s, 3.99 * s, 3.47 * s, 2.18 * s, 7.07 * s)
      ..lineTo(5.84 * s, 9.91 * s)
      ..cubicTo(6.71 * s, 7.31 * s, 9.14 * s, 5.38 * s, 12 * s, 5.38 * s)
      ..close();
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Microsoft Logo ──────────────────────────────────────────────────────────

/// Microsoft four-square logo with brand colors.
class _MicrosoftLogo extends StatelessWidget {
  const _MicrosoftLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MicrosoftLogoPainter());
  }
}

class _MicrosoftLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gap = w * 0.08;
    final halfW = (w - gap) / 2;
    final halfH = (h - gap) / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Top-left: red
    paint.color = const Color(0xFFF25022);
    canvas.drawRect(Rect.fromLTWH(0, 0, halfW, halfH), paint);

    // Top-right: green
    paint.color = const Color(0xFF7FBA00);
    canvas.drawRect(Rect.fromLTWH(halfW + gap, 0, halfW, halfH), paint);

    // Bottom-left: blue
    paint.color = const Color(0xFF00A4EF);
    canvas.drawRect(Rect.fromLTWH(0, halfH + gap, halfW, halfH), paint);

    // Bottom-right: yellow
    paint.color = const Color(0xFFFFB900);
    canvas.drawRect(
      Rect.fromLTWH(halfW + gap, halfH + gap, halfW, halfH),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
