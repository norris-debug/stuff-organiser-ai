import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_face.dart';
import 'mascot_widget.dart';

  void paintMascotBlindfolded(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint hair = Paint()..color = pack.seed;
    final Paint band = Paint()..color = kMascotInk;

    final Offset head = Offset(w / 2, h * 0.58);
    final double r = w * 0.28;
    for (int i = -2; i <= 2; i++) {
      final Path spike = Path()
        ..moveTo(head.dx + i * r * 0.42 - r * 0.18, head.dy - r * 0.55)
        ..lineTo(head.dx + i * r * 0.42, head.dy - r * (1.25 + (i == 0 ? 0.25 : 0.0)))
        ..lineTo(head.dx + i * r * 0.42 + r * 0.18, head.dy - r * 0.55)
        ..close();
      canvas.drawPath(spike, hair);
    }
    canvas.drawCircle(head, r, body);
    paintMascotFace(canvas, head, r, pack, mood);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(head.dx, head.dy - r * 0.12),
          width: r * 1.9,
          height: r * 0.42,
        ),
        Radius.circular(r * 0.2),
      ),
      band,
    );
  }

  void paintMascotStrawHat(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint hat = Paint()..color = pack.seed;

    final Offset head = Offset(w / 2, h * 0.58);
    final double r = w * 0.27;
    canvas.drawCircle(head, r, body);
    paintMascotFace(canvas, head, r, pack, mood);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx, head.dy - r * 0.68),
        width: r * 2.4,
        height: h * 0.1,
      ),
      hat,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(head.dx, head.dy - r * 0.9),
        width: r * 1.4,
        height: r * 1.1,
      ),
      math.pi,
      math.pi,
      true,
      hat,
    );
    final Paint scar = Paint()
      ..color = kMascotInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(head.dx - r * 0.36, head.dy - r * 0.1),
      Offset(head.dx - r * 0.36, head.dy + r * 0.3),
      scar,
    );
    canvas.drawLine(
      Offset(head.dx - r * 0.5, head.dy + r * 0.06),
      Offset(head.dx - r * 0.22, head.dy + r * 0.06),
      scar,
    );
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
