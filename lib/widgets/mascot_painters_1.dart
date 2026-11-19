import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_face.dart';
import 'mascot_widget.dart';

/// v0.8.3: bunny and cat painted from Leaf's approved animal specs -
/// heads only on their coded pastel tiles: nothing below the neck and
/// the whole mascot inside the tile. Dot-eye base, flat fills, no
/// outlines. Robot and axolotl keep their v1 placeholder shapes
/// (they are not selectable since v0.6.8).
/// v0.8.5: cat whisker dots removed per the closed mascot ruling - the
/// face is dot-eyes with glints, nose, smile and cheek patches only.

void _drawPastelTile(Canvas canvas, Size size, Color color) {
  canvas.drawRect(Offset.zero & size, Paint()..color = color);
}

void paintMascotBunny(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Paint body = Paint()..color = const Color(0xFFF6F1E7);
  final Paint inner = Paint()..color = const Color(0xFFF3C1CF);
  final Offset head = Offset(w * 0.5, h * 0.55);
  final double r = w * 0.34;
  final bool happy = mood != MascotMood.idle;

  _drawPastelTile(canvas, size, const Color(0xFFFBE7EE));
  // Tall rounded ears with one gently flopped when neutral; both lift on
  // happy - the small pose change from the spec.
  final List<Offset> tips = happy
      ? <Offset>[Offset(w * 0.34, h * 0.05), Offset(w * 0.64, h * 0.04)]
      : <Offset>[Offset(w * 0.34, h * 0.05), Offset(w * 0.68, h * 0.13)];
  for (int i = 0; i < 2; i++) {
    final double side = i == 0 ? -1.0 : 1.0;
    final Offset base = Offset(head.dx + side * r * 0.45, head.dy - r * 0.62);
    final Offset tip = tips[i];
    final Path ear = Path()
      ..moveTo(base.dx - w * 0.075, base.dy)
      ..quadraticBezierTo(
        base.dx - w * 0.09 + (tip.dx - base.dx) * 0.45,
        (base.dy + tip.dy) * 0.5,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        base.dx + w * 0.09 + (tip.dx - base.dx) * 0.45,
        (base.dy + tip.dy) * 0.5,
        base.dx + w * 0.075,
        base.dy,
      )
      ..close();
    canvas.drawPath(ear, body);
    final Paint innerStroke = Paint()
      ..color = inner.color
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(base.dx + side * w * 0.012, base.dy - h * 0.015),
      Offset(tip.dx + side * w * 0.01, tip.dy + h * 0.035),
      innerStroke,
    );
  }
  canvas.drawCircle(head, r, body);
  canvas.drawOval(
    Rect.fromCenter(
      center: head.translate(0, r * 0.16),
      width: r * 0.16,
      height: r * 0.11,
    ),
    Paint()..color = const Color(0xFFE8A0B4),
  );
  paintMascotFace(canvas, head, r, pack, mood, blush: const Color(0xFFF5C6CF));
}

void paintMascotCat(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Paint body = Paint()..color = const Color(0xFFAEB8C2);
  final Paint cream = Paint()..color = const Color(0xFFF1E9DC);
  final Offset head = Offset(w * 0.49, h * 0.53);
  final double r = w * 0.35;

  _drawPastelTile(canvas, size, const Color(0xFFF2EEE4));
  for (final double sign in <double>[-1, 1]) {
    final Path ear = Path()
      ..moveTo(head.dx + sign * r * 0.9, head.dy - r * 0.4)
      ..quadraticBezierTo(
        head.dx + sign * r * 1.02,
        head.dy - r * 0.95,
        head.dx + sign * r * 0.68,
        head.dy - r * 1.14,
      )
      ..quadraticBezierTo(
        head.dx + sign * r * 0.42,
        head.dy - r * 1.02,
        head.dx + sign * r * 0.16,
        head.dy - r * 0.52,
      )
      ..close();
    canvas.drawPath(ear, body);
    final Paint innerStroke = Paint()
      ..color = const Color(0xFFE8C9CF)
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(head.dx + sign * r * 0.56, head.dy - r * 0.6),
      Offset(head.dx + sign * r * 0.66, head.dy - r * 0.9),
      innerStroke,
    );
  }
  canvas.drawCircle(head, r, body);
  canvas.drawOval(
    Rect.fromCenter(
      center: head.translate(0, r * 0.34),
      width: r * 1.05,
      height: r * 0.72,
    ),
    cream,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: head.translate(0, r * 0.1),
      width: r * 0.14,
      height: r * 0.1,
    ),
    Paint()..color = const Color(0xFF6E625A),
  );
  paintMascotFace(canvas, head, r, pack, mood, blush: const Color(0xFFF0C0C0));
}

void paintMascotRobot(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Paint body = Paint()..color = pack.accent;
  final Paint face = Paint()..color = pack.seed;

  final Paint antenna = Paint()
    ..color = kMascotInk
    ..strokeWidth = w * 0.02
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(w / 2, h * 0.36), Offset(w / 2, h * 0.2), antenna);
  canvas.drawCircle(Offset(w / 2, h * 0.18), w * 0.05, face);

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w / 2, h * 0.58), width: w * 0.6, height: h * 0.48),
      Radius.circular(w * 0.14),
    ),
    body,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w / 2, h * 0.57), width: w * 0.44, height: h * 0.3),
      Radius.circular(w * 0.08),
    ),
    face,
  );
  paintMascotFace(canvas, Offset(w / 2, h * 0.56), w * 0.16, pack, mood);
}

void paintMascotAxolotl(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Paint body = Paint()..color = pack.accent;
  final Offset head = Offset(w / 2, h * 0.58);
  final double r = w * 0.28;

  for (int i = 0; i < 3; i++) {
    for (final double sign in <double>[-1, 1]) {
      canvas.drawCircle(
        Offset(head.dx + sign * (r + w * 0.06), head.dy - r * 0.5 + i * r * 0.5),
        w * 0.045,
        body,
      );
    }
  }
  canvas.drawCircle(head, r, body);
  paintMascotFace(canvas, head, r, pack, mood);
}
