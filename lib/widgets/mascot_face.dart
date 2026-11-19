import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_widget.dart';

  const Color kMascotInk = Color(0xFF2E2E38);

  void paintMascotFace(Canvas canvas, Offset center, double r, ThemePack pack, MascotMood mood) {
    final bool happy = mood != MascotMood.idle;
    final double eyeY = center.dy - r * 0.12;
    final double eyeDx = r * 0.36;

    if (happy) {
      final Paint arc = Paint()
        ..color = kMascotInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(center.dx - eyeDx, eyeY), radius: r * 0.2),
        0.15 * math.pi,
        0.7 * math.pi,
        false,
        arc,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(center.dx + eyeDx, eyeY), radius: r * 0.2),
        0.15 * math.pi,
        0.7 * math.pi,
        false,
        arc,
      );
    } else {
      final Paint eye = Paint()..color = kMascotInk;
      canvas.drawCircle(Offset(center.dx - eyeDx, eyeY), r * 0.12, eye);
      canvas.drawCircle(Offset(center.dx + eyeDx, eyeY), r * 0.12, eye);
    }

    final Paint blush = Paint()..color = pack.accent.withAlpha(90);
    canvas.drawCircle(Offset(center.dx - eyeDx * 1.5, center.dy + r * 0.18), r * 0.13, blush);
    canvas.drawCircle(Offset(center.dx + eyeDx * 1.5, center.dy + r * 0.18), r * 0.13, blush);

    if (mood == MascotMood.cheer) {
      final Paint mouth = Paint()..color = kMascotInk;
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(0, r * 0.22),
          width: r * 0.3,
          height: r * 0.34,
        ),
        mouth,
      );
    } else {
      final Paint mouth = Paint()
        ..color = kMascotInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.09
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: center.translate(0, -r * 0.08),
          width: r * 0.36,
          height: r * 0.28,
        ),
        0.12 * math.pi,
        0.76 * math.pi,
        false,
        mouth,
      );
    }
  }
