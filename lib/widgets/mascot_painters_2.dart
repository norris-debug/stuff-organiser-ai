import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_face.dart';
import 'mascot_widget.dart';

/// v0.8: ramen and berry painted from Leaf's food finals - head-only busts
/// on their coded pastel tiles, dot-eye base, flat fills, no outlines.
/// The pastel tile is painted in code at render time; note and speaker keep
/// the old placeholder style (music pack is retired from the picker).

void _drawPastelTile(Canvas canvas, Size size, Color color) {
  canvas.drawRect(Offset.zero & size, Paint()..color = color);
}

void paintMascotRamen(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;

  _drawPastelTile(canvas, size, const Color(0xFFF2EEE4));
  // Bowl head mass, near-cropped by the bottom edge.
  canvas.drawOval(
    Rect.fromCenter(center: Offset(w * 0.5, h * 0.66), width: w * 0.9, height: h * 0.7),
    Paint()..color = const Color(0xFFF8E2C8),
  );
  canvas.drawOval(
    Rect.fromCenter(center: Offset(w * 0.5, h * 0.95), width: w * 0.34, height: h * 0.08),
    Paint()..color = const Color(0xFFF3D6B4),
  );
  // Broth bed behind the bang-band.
  canvas.drawOval(
    Rect.fromCenter(center: Offset(w * 0.5, h * 0.42), width: w * 0.76, height: h * 0.16),
    Paint()..color = const Color(0xFFF48F83),
  );
  // Solid bang-band over the rim: noodles hanging as a flat fringe.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.35, w * 0.7, h * 0.17),
      Radius.circular(w * 0.085),
    ),
    Paint()..color = const Color(0xFFF48F83),
  );
  // Flat noodle stripes inside the band: shapes, not line-art.
  for (final double dx in const <double>[-0.19, 0.0, 0.19]) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * (0.5 + dx) - w * 0.028, h * 0.37, w * 0.056, h * 0.13),
        Radius.circular(w * 0.028),
      ),
      Paint()..color = const Color(0xFFEA6F63),
    );
  }
  // Naruto swirl tucked at one side: white disc with a chunky pink arc.
  final Offset swirl = Offset(w * 0.27, h * 0.42);
  canvas.drawCircle(swirl, w * 0.085, Paint()..color = const Color(0xFFFFFFFF));
  final Paint spiral = Paint()
    ..color = const Color(0xFFF79B88)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * 0.034
    ..strokeCap = StrokeCap.round;
  canvas.drawArc(
    Rect.fromCenter(center: swirl, width: w * 0.09, height: w * 0.09),
    math.pi * 0.7,
    math.pi * 1.4,
    false,
    spiral,
  );
  paintMascotFace(canvas, Offset(w * 0.5, h * 0.66), w * 0.17, pack, mood, blush: const Color(0xFFFFB19A));
}

void paintMascotBerry(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Offset head = Offset(w * 0.5, h * 0.56);
  final double r = w * 0.34;

  _drawPastelTile(canvas, size, const Color(0xFFFBE7EE));
  // Stem + single leaf.
  canvas.drawRect(
    Rect.fromLTWH(w * 0.485, h * 0.12, w * 0.03, h * 0.14),
    Paint()..color = const Color(0xFF2F7E44),
  );
  final Path leaf = Path()
    ..moveTo(w * 0.515, h * 0.2)
    ..quadraticBezierTo(w * 0.7, h * 0.12, w * 0.67, h * 0.25)
    ..quadraticBezierTo(w * 0.6, h * 0.33, w * 0.515, h * 0.2)
    ..close();
  canvas.drawPath(leaf, Paint()..color = const Color(0xFF7FDDBE));
  // Berry body: the head itself.
  canvas.drawCircle(head, r, Paint()..color = const Color(0xFFF07D82));
  // Seeds sparse and low, so the face owns the center.
  final Paint seed = Paint()..color = const Color(0xFFB2555E);
  for (final Offset spot in const <Offset>[
    Offset(-0.23, 0.2),
    Offset(0.23, 0.2),
    Offset(-0.1, 0.29),
    Offset(0.1, 0.29),
  ]) {
    canvas.drawCircle(
      Offset(head.dx + w * spot.dx, head.dy + h * spot.dy),
      w * 0.02,
      seed,
    );
  }
  paintMascotFace(canvas, head, r, pack, mood, blush: const Color(0xFFF0878C));
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
