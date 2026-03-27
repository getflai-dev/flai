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
    final fgColor = isPrimary ? theme.colors.background : theme.colors.foreground;

    final (label, logo) = switch (type) {
      SocialAuthType.apple => (
          'Continue with Apple',
          _AppleLogo(color: fgColor),
        ),
      SocialAuthType.google => (
          'Continue with Google',
          const _GoogleLogo(),
        ),
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
          backgroundColor: isPrimary ? theme.colors.foreground : Colors.transparent,
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

/// Google "G" logo with the four brand colors.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w * 0.45;
    final strokeWidth = w * 0.18;

    // Draw the G shape as colored arcs
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Blue (right side, -45° to 45°)
    paint.color = _blue;
    canvas.drawArc(rect, -0.8, 1.6, false, paint);

    // Green (bottom right, 45° to 135°)
    paint.color = _green;
    canvas.drawArc(rect, 0.8, 1.0, false, paint);

    // Yellow (bottom left, 135° to 180°)
    paint.color = _yellow;
    canvas.drawArc(rect, 1.8, 0.8, false, paint);

    // Red (top, 180° to 315°)
    paint.color = _red;
    canvas.drawArc(rect, 2.6, 1.0, false, paint);

    // Blue horizontal bar (the cross of the G)
    final barPaint = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx - w * 0.02,
        center.dy - strokeWidth / 2,
        center.dx + radius + strokeWidth / 2,
        center.dy + strokeWidth / 2,
      ),
      barPaint,
    );
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
  static const _red = Color(0xFFF25022);
  static const _green = Color(0xFF7FBA00);
  static const _blue = Color(0xFF00A4EF);
  static const _yellow = Color(0xFFFFB900);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gap = w * 0.06;
    final halfW = (w - gap) / 2;
    final halfH = (h - gap) / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Top-left: red
    paint.color = _red;
    canvas.drawRect(Rect.fromLTWH(0, 0, halfW, halfH), paint);

    // Top-right: green
    paint.color = _green;
    canvas.drawRect(Rect.fromLTWH(halfW + gap, 0, halfW, halfH), paint);

    // Bottom-left: blue
    paint.color = _blue;
    canvas.drawRect(Rect.fromLTWH(0, halfH + gap, halfW, halfH), paint);

    // Bottom-right: yellow
    paint.color = _yellow;
    canvas.drawRect(
        Rect.fromLTWH(halfW + gap, halfH + gap, halfW, halfH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
