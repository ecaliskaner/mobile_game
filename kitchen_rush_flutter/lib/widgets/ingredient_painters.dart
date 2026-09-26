import 'package:flutter/material.dart';

/// Hand-drawn vector glyphs for the ingredients Lucide has no icon for
/// (tomato, onion, garlic, pepper, cheese). Each painter draws a small,
/// flat, gradient-shaded shape — never emoji, never a raster image.

class TomatoPainter extends CustomPainter {
  const TomatoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFF9166), Color(0xFFE6432C), Color(0xFFA8241A)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawCircle(Offset(w * 0.5, h * 0.56), w * 0.42, body);

    final leaf = Paint()..color = const Color(0xFF4C9A3B);
    final path = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.64, h * 0.24)
      ..lineTo(w * 0.5, h * 0.18)
      ..lineTo(w * 0.36, h * 0.24)
      ..close();
    canvas.drawPath(path, leaf);

    final highlight = Paint()..color = Colors.white.withOpacity(0.32);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.38, h * 0.44), width: w * 0.22, height: h * 0.14),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OnionPainter extends CustomPainter {
  const OnionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFF6D3E8), Color(0xFFC77BB0), Color(0xFF7D3F68)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.82), body);

    final line = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawArc(Rect.fromLTWH(w * 0.22, h * 0.12, w * 0.3, h * 0.78), -1.4, 2.6, false, line);
    canvas.drawArc(Rect.fromLTWH(w * 0.48, h * 0.12, w * 0.3, h * 0.78), 2.0, 2.6, false, line);

    final sprout = Paint()
      ..color = const Color(0xFF4C9A3B)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, h * 0.1), Offset(w * 0.55, h * 0.0), sprout);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GarlicPainter extends CustomPainter {
  const GarlicPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFAF0), Color(0xFFF0E6CF), Color(0xFFD3C095)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawOval(Rect.fromLTWH(w * 0.12, h * 0.12, w * 0.76, h * 0.76), body);

    final line = Paint()
      ..color = const Color(0xFFB89F6E).withOpacity(0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w * 0.5, h * 0.12), Offset(w * 0.5, h * 0.88), line);
    canvas.drawLine(Offset(w * 0.32, h * 0.18), Offset(w * 0.32, h * 0.82), line);
    canvas.drawLine(Offset(w * 0.68, h * 0.18), Offset(w * 0.68, h * 0.82), line);

    final stem = Paint()
      ..color = const Color(0xFF8A744A)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(w * 0.42, h * 0.12)
      ..quadraticBezierTo(w * 0.5, h * 0.0, w * 0.58, h * 0.12);
    canvas.drawPath(path, stem);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PepperPainter extends CustomPainter {
  const PepperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6A5A), Color(0xFFB81F1A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final path = Path()
      ..moveTo(w * 0.32, h * 0.28)
      ..cubicTo(w * 0.65, h * 0.12, w * 0.95, h * 0.35, w * 0.85, h * 0.6)
      ..cubicTo(w * 0.75, h * 0.92, w * 0.4, h * 0.98, w * 0.28, h * 0.78)
      ..cubicTo(w * 0.18, h * 0.6, w * 0.22, h * 0.42, w * 0.32, h * 0.28)
      ..close();
    canvas.drawPath(path, body);

    final stem = Paint()
      ..color = const Color(0xFF4C9A3B)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.32, h * 0.28), Offset(w * 0.26, h * 0.12), stem);

    final highlight = Paint()..color = Colors.white.withOpacity(0.26);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.42, h * 0.42), width: w * 0.16, height: h * 0.24),
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CheesePainter extends CustomPainter {
  const CheesePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE07A), Color(0xFFE8A017)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final path = Path()
      ..moveTo(w * 0.14, h * 0.86)
      ..lineTo(w * 0.5, h * 0.12)
      ..lineTo(w * 0.86, h * 0.86)
      ..close();
    canvas.drawPath(path, body);
    final border = Paint()
      ..color = const Color(0xFFC98A12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, border);

    final hole = Paint()..color = const Color(0xFFD99311);
    canvas.drawCircle(Offset(w * 0.42, h * 0.62), w * 0.06, hole);
    canvas.drawCircle(Offset(w * 0.6, h * 0.7), w * 0.045, hole);
    canvas.drawCircle(Offset(w * 0.5, h * 0.44), w * 0.035, hole);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
