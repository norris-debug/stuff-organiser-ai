import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_widget.dart';

const Color kMascotInk = Color(0xFF2E2E38);

/// v0.8 face base (Leaf's locked spec): dot eyes with a tiny white glint in
/// every mood - no line eyes - soft blush, and a small curved mouth that
/// widens into a smile when happy; celebration keeps the open-mouth look.
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

  final Paint eye = Paint()..color = kMascotInk;
  canvas.drawCircle(Offset(center.dx - eyeDx, eyeY), r * 0.12, eye);
  canvas.drawCircle(Offset(center.dx + eyeDx, eyeY), r * 0.12, eye);
  final Paint glint = Paint()..color = const Color(0xFFFFFFFF);
  final double glintDx = r * 0.035;
  final double glintDy = r * 0.05;
  canvas.drawCircle(Offset(center.dx - eyeDx - glintDx, eyeY - glintDy), r * 0.04, glint);
  canvas.drawCircle(Offset(center.dx + eyeDx - glintDx, eyeY - glintDy), r * 0.04, glint);

  final bool happy = mood != MascotMood.idle;
  final Paint blushPaint = Paint()..color = (blush ?? pack.accent).withAlpha(100);
  final double blushY = center.dy + r * 0.2;
  final double blushR = happy ? r * 0.15 : r * 0.12;
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
  } else {
    final Paint mouth = Paint()
      ..color = kMascotInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, r * 0.26),
        width: happy ? r * 0.52 : r * 0.36,
        height: r * 0.34,
      ),
      0.15 * math.pi,
      0.7 * math.pi,
      false,
      mouth,
    );
  }
}
