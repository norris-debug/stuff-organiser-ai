import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_face.dart';
import 'mascot_widget.dart';

  void paintMascotRamen(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
    final double w = size.width;
    final double h = size.height;
    final Paint bowl = Paint()..color = pack.accent;
    final Paint broth = Paint()..color = pack.seed;

    canvas.drawArc(
      Rect.fromCenter(center: Offset(w / 2, h * 0.6), width: w * 0.68, height: h * 0.4),
      0,
      math.pi,
      true,
      bowl,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.4), width: w * 0.68, height: h * 0.2),
      broth,
    );

    final Paint noodle = Paint()
      ..color = kMascotInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final double x = w / 2 + (i - 1) * w * 0.16;
      final Path path = Path()
        ..moveTo(x - w * 0.06, h * 0.42)
        ..quadraticBezierTo(x, h * 0.27, x + w * 0.06, h * 0.42);
      canvas.drawPath(path, noodle);
    }
    paintMascotFace(canvas, Offset(w / 2, h * 0.6), w * 0.17, pack, mood);
  }

  void paintMascotBerry(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Offset head = Offset(w / 2, h * 0.58);
    final double r = w * 0.28;

    final Path leaf = Path()
      ..moveTo(head.dx, head.dy - r)
      ..quadraticBezierTo(head.dx + w * 0.13, head.dy - r * 1.55, head.dx + w * 0.02, head.dy - r * 1.5)
      ..quadraticBezierTo(head.dx - w * 0.09, head.dy - r * 1.4, head.dx, head.dy - r)
      ..close();
    canvas.drawPath(leaf, Paint()..color = pack.seed);
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
