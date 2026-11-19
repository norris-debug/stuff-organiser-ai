import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_face.dart';
import 'mascot_widget.dart';

/// v0.8.8: legacy code-painted mascots, unchanged from their previous
/// homes. Robot and axolotl are not selectable since v0.6.8; note and
/// speaker belong to the retired music pack; ninja, idol and mage are
/// the anime alternates held here until the locked anime-three swap
/// (twin tails, glasses boy, bob cut) lands as its own change.

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

void paintMascotNote(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Paint body = Paint()..color = pack.accent;
  final Paint stem = Paint()..color = pack.seed;
  final double x = w * 0.44;

  canvas.drawRect(Rect.fromLTWH(x, h * 0.2, w * 0.08, h * 0.5), stem);
  final Path flag = Path()
    ..moveTo(x + w * 0.08, h * 0.2)
    ..quadraticBezierTo(x + w * 0.34, h * 0.3, x + w * 0.22, h * 0.46)
    ..lineTo(x + w * 0.08, h * 0.42)
    ..close();
  canvas.drawPath(flag, stem);
  canvas.drawOval(
    Rect.fromCenter(center: Offset(x - w * 0.04, h * 0.72), width: w * 0.28, height: h * 0.2),
    body,
  );
  paintMascotFace(canvas, Offset(x - w * 0.04, h * 0.72), w * 0.1, pack, mood);
}

void paintMascotSpeaker(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Paint body = Paint()..color = pack.accent;
  final Paint cone = Paint()..color = pack.seed;

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w / 2, h * 0.58), width: w * 0.56, height: h * 0.56),
      Radius.circular(w * 0.12),
    ),
    body,
  );
  canvas.drawCircle(Offset(w / 2, h * 0.66), w * 0.14, cone);
  canvas.drawCircle(Offset(w / 2, h * 0.42), w * 0.06, cone);
  paintMascotFace(canvas, Offset(w / 2, h * 0.52), w * 0.13, pack, mood);
}

void paintMascotNinja(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Paint body = Paint()..color = pack.accent;
  final Paint band = Paint()..color = pack.seed;

  final Offset head = Offset(w / 2, h * 0.58);
  final double r = w * 0.28;
  canvas.drawCircle(head, r, body);
  paintMascotFace(canvas, head, r, pack, mood);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(head.dx, head.dy - r * 0.45),
        width: r * 2.1,
        height: r * 0.34,
      ),
      Radius.circular(r * 0.16),
    ),
    band,
  );
  for (final double sign in <double>[-1, 1]) {
    final Path tail = Path()
      ..moveTo(head.dx + sign * r, head.dy - r * 0.45)
      ..quadraticBezierTo(
        head.dx + sign * r * 1.35,
        head.dy - r * 0.6,
        head.dx + sign * r * 1.25,
        head.dy - r * 0.15,
      )
      ..lineTo(head.dx + sign * r * 1.05, head.dy - r * 0.3)
      ..close();
    canvas.drawPath(tail, band);
  }
}

void paintMascotIdol(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Paint body = Paint()..color = pack.accent;
  final Paint tail = Paint()..color = pack.seed;

  final Offset head = Offset(w / 2, h * 0.6);
  final double r = w * 0.28;
  for (final double sign in <double>[-1, 1]) {
    canvas.drawCircle(
      Offset(head.dx + sign * r * 0.95, head.dy - r * 0.15),
      w * 0.11,
      tail,
    );
    canvas.drawCircle(
      Offset(head.dx + sign * r * 1.08, head.dy + r * 0.45),
      w * 0.08,
      tail,
    );
  }
  canvas.drawCircle(head, r, body);
  paintMascotFace(canvas, head, r, pack, mood);
  for (final double sign in <double>[-1, 1]) {
    final Path fringe = Path()
      ..moveTo(head.dx + sign * r * 0.2, head.dy - r)
      ..quadraticBezierTo(
        head.dx + sign * r * 0.75,
        head.dy - r * 0.75,
        head.dx + sign * r * 0.55,
        head.dy - r * 0.35,
      )
      ..close();
    canvas.drawPath(fringe, tail);
  }
  canvas.drawCircle(Offset(head.dx, head.dy - r * 1.02), w * 0.05, tail);
}

void paintMascotMage(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Paint body = Paint()..color = pack.accent;
  final Paint hat = Paint()..color = pack.seed;

  final Offset head = Offset(w / 2, h * 0.6);
  final double r = w * 0.27;
  canvas.drawCircle(head, r, body);
  paintMascotFace(canvas, head, r, pack, mood);
  final Path cone = Path()
    ..moveTo(head.dx, head.dy - r * 1.85)
    ..lineTo(head.dx - r * 0.95, head.dy - r * 0.55)
    ..lineTo(head.dx + r * 0.95, head.dy - r * 0.55)
    ..close();
  canvas.drawPath(cone, hat);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(head.dx, head.dy - r * 0.58),
        width: r * 2.2,
        height: h * 0.07,
      ),
      Radius.circular(w * 0.03),
    ),
    hat,
  );
  canvas.drawCircle(Offset(head.dx, head.dy - r * 2.05), w * 0.045, hat);
  canvas.drawCircle(Offset(head.dx + r * 0.35, head.dy - r * 2.0), w * 0.03, hat);
}
