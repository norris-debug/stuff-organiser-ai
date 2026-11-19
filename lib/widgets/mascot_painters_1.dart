import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_face.dart';
import 'mascot_widget.dart';

  void paintMascotBunny(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint inner = Paint()..color = pack.seed;

    for (final double sign in <double>[-1, 1]) {
      canvas.save();
      canvas.translate(w / 2 + sign * w * 0.16, h * 0.26);
      canvas.rotate(sign * 0.16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w * 0.13, height: h * 0.32),
          Radius.circular(w * 0.065),
        ),
        body,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w * 0.05, height: h * 0.22),
          Radius.circular(w * 0.025),
        ),
        inner,
      );
      canvas.restore();
    }

    final Offset head = Offset(w / 2, h * 0.6);
    final double r = w * 0.3;
    canvas.drawCircle(head, r, body);
    paintMascotFace(canvas, head, r, pack, mood);
  }

  void paintMascotCat(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Offset head = Offset(w / 2, h * 0.6);
    final double r = w * 0.3;

    for (final double sign in <double>[-1, 1]) {
      final Path ear = Path()
        ..moveTo(head.dx + sign * r * 0.85, head.dy - r * 0.5)
        ..lineTo(head.dx + sign * r * 0.35, head.dy - r * 1.25)
        ..lineTo(head.dx + sign * r * 0.05, head.dy - r * 0.6)
        ..close();
      canvas.drawPath(ear, body);
    }
    canvas.drawCircle(head, r, body);
    paintMascotFace(canvas, head, r, pack, mood);

    final Paint whisker = Paint()
      ..color = kMascotInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;
    for (final double sign in <double>[-1, 1]) {
      canvas.drawLine(
        Offset(head.dx + sign * r * 0.35, head.dy + r * 0.08),
        Offset(head.dx + sign * r * 0.95, head.dy - r * 0.02),
        whisker,
      );
      canvas.drawLine(
        Offset(head.dx + sign * r * 0.35, head.dy + r * 0.26),
        Offset(head.dx + sign * r * 0.95, head.dy + r * 0.34),
        whisker,
      );
    }
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
