import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_face.dart';
import 'mascot_widget.dart';

  void paintMascotRedPanda(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint dark = Paint()..color = pack.seed;
    final Offset head = Offset(w / 2, h * 0.6);
    final double r = w * 0.3;

    for (final double sign in <double>[-1, 1]) {
      canvas.drawCircle(
        Offset(head.dx + sign * r * 0.78, head.dy - r * 0.85),
        w * 0.09,
        dark,
      );
    }
    canvas.drawCircle(head, r, body);
    final Paint cheek = Paint()..color = pack.seed.withAlpha(120);
    canvas.drawCircle(Offset(head.dx - r * 0.62, head.dy + r * 0.2), r * 0.3, cheek);
    canvas.drawCircle(Offset(head.dx + r * 0.62, head.dy + r * 0.2), r * 0.3, cheek);
    paintMascotFace(canvas, head, r, pack, mood);
  }

  void paintMascotQuokka(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint inner = Paint()..color = pack.seed;
    final Offset head = Offset(w / 2, h * 0.6);
    final double r = w * 0.3;

    for (final double sign in <double>[-1, 1]) {
      final Path ear = Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(head.dx + sign * r * 0.8, head.dy - r * 0.8),
            width: w * 0.14,
            height: h * 0.18,
          ),
        );
      canvas.drawPath(ear, body);
    }
    canvas.drawCircle(head, r, body);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx, head.dy + r * 0.35),
        width: r * 0.9,
        height: r * 0.5,
      ),
      Paint()..color = inner.color.withAlpha(110),
    );
    paintMascotFace(canvas, head, r, pack, mood);
  }

  void paintMascotSeaOtter(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Offset head = Offset(w / 2, h * 0.58);
    final double r = w * 0.29;

    for (final double sign in <double>[-1, 1]) {
      canvas.drawCircle(
        Offset(head.dx + sign * r * 0.85, head.dy - r * 0.72),
        w * 0.06,
        body,
      );
    }
    canvas.drawCircle(head, r, body);
    final Paint muzzle = Paint()..color = pack.seed.withAlpha(120);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx, head.dy + r * 0.32),
        width: r * 0.85,
        height: r * 0.5,
      ),
      muzzle,
    );
    final Paint whisker = Paint()
      ..color = kMascotInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;
    for (final double sign in <double>[-1, 1]) {
      canvas.drawLine(
        Offset(head.dx + sign * r * 0.4, head.dy + r * 0.3),
        Offset(head.dx + sign * r * 0.98, head.dy + r * 0.2),
        whisker,
      );
      canvas.drawLine(
        Offset(head.dx + sign * r * 0.4, head.dy + r * 0.44),
        Offset(head.dx + sign * r * 0.95, head.dy + r * 0.52),
        whisker,
      );
    }
    paintMascotFace(canvas, head, r, pack, mood);
  }
