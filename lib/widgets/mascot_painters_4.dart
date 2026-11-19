import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_face.dart';
import 'mascot_widget.dart';

/// v0.8: cake, salad and pizza painted from Leaf's food finals - head-only
/// busts on their coded pastel tiles, dot-eye base, flat fills, no outlines.
/// The pastel tile is painted in code at render time.

void _drawPastelTile(Canvas canvas, Size size, Color color) {
  canvas.drawRect(Offset.zero & size, Paint()..color = color);
}

void paintMascotCake(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;

  _drawPastelTile(canvas, size, const Color(0xFFFBEFDD));
  // Top tier as the bust mass, cropped by the bottom edge.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.4, w * 0.72, h * 0.66),
      Radius.circular(w * 0.06),
    ),
    Paint()..color = const Color(0xFFFCEBD6),
  );
  // Cherry dot up top.
  canvas.drawCircle(Offset(w * 0.5, h * 0.32), w * 0.07, Paint()..color = const Color(0xFFFF6D62));
  canvas.drawCircle(Offset(w * 0.47, h * 0.3), w * 0.018, Paint()..color = const Color(0xFFFFBDAE));
  // Icing cap with a single wavy drip break across the front.
  final Path icing = Path()
    ..moveTo(w * 0.14, h * 0.47)
    ..lineTo(w * 0.86, h * 0.47)
    ..lineTo(w * 0.86, h * 0.54)
    ..lineTo(w * 0.58, h * 0.54)
    ..quadraticBezierTo(w * 0.5, h * 0.63, w * 0.42, h * 0.54)
    ..lineTo(w * 0.14, h * 0.54)
    ..close();
  canvas.drawPath(icing, Paint()..color = const Color(0xFFF8BFD0));
  paintMascotFace(canvas, Offset(w * 0.5, h * 0.72), w * 0.16, pack, mood, blush: const Color(0xFFFF9E95));
}

void paintMascotSalad(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;

  _drawPastelTile(canvas, size, const Color(0xFFEAF3EC));
  // Three-leaf crown + one tomato accent, tucked behind the bowl rim.
  final Paint leafLight = Paint()..color = const Color(0xFF8BD378);
  final Paint leafDark = Paint()..color = const Color(0xFF4AA85B);
  final Path leafL = Path()
    ..moveTo(w * 0.36, h * 0.5)
    ..quadraticBezierTo(w * 0.2, h * 0.32, w * 0.36, h * 0.24)
    ..quadraticBezierTo(w * 0.44, h * 0.38, w * 0.36, h * 0.5)
    ..close();
  final Path leafM = Path()
    ..moveTo(w * 0.47, h * 0.48)
    ..quadraticBezierTo(w * 0.45, h * 0.24, w * 0.56, h * 0.2)
    ..quadraticBezierTo(w * 0.6, h * 0.38, w * 0.53, h * 0.48)
    ..close();
  final Path leafR = Path()
    ..moveTo(w * 0.62, h * 0.5)
    ..quadraticBezierTo(w * 0.72, h * 0.32, w * 0.62, h * 0.26)
    ..quadraticBezierTo(w * 0.54, h * 0.4, w * 0.62, h * 0.5)
    ..close();
  canvas.drawPath(leafL, leafLight);
  canvas.drawPath(leafR, leafLight);
  canvas.drawPath(leafM, leafDark);
  canvas.drawCircle(Offset(w * 0.76, h * 0.4), w * 0.085, Paint()..color = const Color(0xFFFF6A56));
  canvas.drawCircle(Offset(w * 0.735, h * 0.38), w * 0.022, Paint()..color = const Color(0xFFFFD7C8));
  canvas.drawRect(Rect.fromLTWH(w * 0.745, h * 0.29, w * 0.03, h * 0.04), Paint()..color = const Color(0xFF4A9B58));
  // Bowl head mass + rim, cropped at the bottom.
  canvas.drawOval(
    Rect.fromCenter(center: Offset(w * 0.5, h * 0.72), width: w * 0.84, height: h * 0.62),
    Paint()..color = const Color(0xFFF7E6D1),
  );
  canvas.drawOval(
    Rect.fromCenter(center: Offset(w * 0.5, h * 0.51), width: w * 0.8, height: h * 0.13),
    Paint()..color = const Color(0xFFF1D7C2),
  );
  paintMascotFace(canvas, Offset(w * 0.5, h * 0.7), w * 0.16, pack, mood, blush: const Color(0xFFFF8B76));
}

void paintMascotPizza(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Offset head = Offset(w * 0.5, h * 0.58);
  final double r = w * 0.32;

  _drawPastelTile(canvas, size, const Color(0xFFE7F0F4));
  // Crust ring behind the cheese disc.
  canvas.drawCircle(
    head.translate(0, -h * 0.015),
    w * 0.4,
    Paint()..color = const Color(0xFFD39A36),
  );
  canvas.drawCircle(head, r, Paint()..color = const Color(0xFFF6E2A4));
  // Pepperoni doubles as the cheek accents in both expressions.
  final Paint pepperoni = Paint()..color = const Color(0xFFF36B60);
  canvas.drawCircle(Offset(head.dx - r * 0.62, head.dy + r * 0.24), w * 0.075, pepperoni);
  canvas.drawCircle(Offset(head.dx + r * 0.62, head.dy + r * 0.24), w * 0.075, pepperoni);
  // Transparent blush: the pepperoni are the cheeks.
  paintMascotFace(canvas, head, r, pack, mood, blush: const Color(0x00FFFFFF));
}
