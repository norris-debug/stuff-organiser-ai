import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_widget.dart';

const Color kMascotInk = Color(0xFF2E2E38);

/// v0.8.3 face base (Leaf's locked spec): dot eyes with a tiny white
/// glint in most moods - no line eyes - soft blush, and a small curved
/// mouth. Expression variety: blink closes the eyes into soft arcs,
/// surprised opens them wide with a small o-mouth, and cheer keeps the
/// open-mouth look.
void paintMascotFace(
  Canvas canvas,
  Offset center,
  double r,
  ThemePack pack,
  MascotMood mood, {
  Color? blush,
}) {
  final double eyeY = center.dy - r * 0.12;
  final double eyeDx = r * 0.36;

  final bool wide =
      mood != MascotMood.idle && mood != MascotMood.surprised;
  final bool blink = mood == MascotMood.blink;
  final bool surprised = mood == MascotMood.surprised;

  if (blink) {
    // Closed happy eyes: short upward arcs, no glints.
    final Paint lid = Paint()
      ..color = kMascotInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.09
      ..strokeCap = StrokeCap.round;
    for (final double sign in <double>[-1, 1]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx + sign * eyeDx, eyeY),
          width: r * 0.3,
          height: r * 0.22,
        ),
        1.15 * math.pi,
        0.7 * math.pi,
        false,
        lid,
      );
    }
  } else if (surprised) {
    // Wide-open eyes: white ring with an ink pupil and the glint.
    final Paint ring = Paint()..color = const Color(0xFFFFFFFF);
    final Paint pupil = Paint()..color = kMascotInk;
    for (final double sign in <double>[-1, 1]) {
      final Offset eye = Offset(center.dx + sign * eyeDx, eyeY);
      canvas.drawCircle(eye, r * 0.17, ring);
      canvas.drawCircle(eye, r * 0.11, pupil);
      canvas.drawCircle(
        eye.translate(-r * 0.035, -r * 0.045),
        r * 0.035,
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }
  } else {
    final Paint eye = Paint()..color = kMascotInk;
    canvas.drawCircle(Offset(center.dx - eyeDx, eyeY), r * 0.12, eye);
    canvas.drawCircle(Offset(center.dx + eyeDx, eyeY), r * 0.12, eye);
    final Paint glint = Paint()..color = const Color(0xFFFFFFFF);
    final double glintDx = r * 0.035;
    final double glintDy = r * 0.05;
    canvas.drawCircle(Offset(center.dx - eyeDx - glintDx, eyeY - glintDy), r * 0.04, glint);
    canvas.drawCircle(Offset(center.dx + eyeDx - glintDx, eyeY - glintDy), r * 0.04, glint);
  }

  final Paint blushPaint = Paint()..color = (blush ?? pack.accent).withAlpha(100);
  final double blushY = center.dy + r * 0.2;
  final double blushR = wide ? r * 0.15 : r * 0.12;
  canvas.drawCircle(Offset(center.dx - eyeDx * 1.55, blushY), blushR, blushPaint);
  canvas.drawCircle(Offset(center.dx + eyeDx * 1.55, blushY), blushR, blushPaint);

  if (mood == MascotMood.cheer) {
    final Paint mouth = Paint()..color = kMascotInk;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, r * 0.4),
        width: r * 0.3,
        height: r * 0.34,
      ),
      mouth,
    );
  } else if (surprised) {
    final Paint mouth = Paint()
      ..color = kMascotInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center.translate(0, r * 0.34), r * 0.09, mouth);
  } else {
    final Paint mouth = Paint()
      ..color = kMascotInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, r * 0.26),
        width: wide ? r * 0.52 : r * 0.36,
        height: r * 0.34,
      ),
      0.15 * math.pi,
      0.7 * math.pi,
      false,
      mouth,
    );
  }
}
