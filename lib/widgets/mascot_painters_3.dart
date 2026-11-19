import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_face.dart';
import 'mascot_widget.dart';

/// v0.8: red panda, quokka and sea otter painted from Leaf's approved
/// animal specs - head-only busts on their coded pastel tiles, dot-eye
/// base, flat fills, no outlines. The pastel tile is painted in code at
/// render time; that per-mascot pastel is the coded bg value.

void _drawPastelTile(Canvas canvas, Size size, Color color) {
  canvas.drawRect(Offset.zero & size, Paint()..color = color);
}

/// Soft bust mass cropped by the bottom edge: head-only framing that
/// still anchors the character inside the tile.
void _bust(Canvas canvas, Size size, Color color) {
  final double w = size.width;
  final double h = size.height;
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w / 2, h * 0.98),
      width: w * 0.94,
      height: h * 0.44,
    ),
    Paint()..color = color,
  );
}

void paintMascotRedPanda(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Paint body = Paint()..color = const Color(0xFFE8813D);
  final Paint cream = Paint()..color = const Color(0xFFF7E8D3);
  final Offset head = Offset(w * 0.51, h * 0.5);
  final double r = w * 0.33;

  _drawPastelTile(canvas, size, const Color(0xFFFBEFDD));
  for (final double sign in <double>[-1, 1]) {
    final Offset earC = Offset(head.dx + sign * r * 0.72, head.dy - r * 0.82);
    canvas.drawCircle(earC, w * 0.105, body);
    canvas.drawCircle(
      Offset(earC.dx + sign * w * 0.012, earC.dy - w * 0.014),
      w * 0.055,
      cream,
    );
  }
  _bust(canvas, size, const Color(0xFFE8813D));
  canvas.drawCircle(head, r, body);
  canvas.drawOval(
    Rect.fromCenter(
      center: head.translate(0, r * 0.46),
      width: r * 1.14,
      height: r * 0.78,
    ),
    cream,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: head.translate(0, r * 0.02),
      width: r * 0.74,
      height: r * 0.6,
    ),
    cream,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: head.translate(0, r * 0.28),
      width: r * 0.16,
      height: r * 0.11,
    ),
    Paint()..color = const Color(0xFF6B3A1E),
  );
  paintMascotFace(canvas, head, r, pack, mood, blush: const Color(0xFFF5A97E));
}

void paintMascotQuokka(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Paint body = Paint()..color = const Color(0xFFB98A5E);
  final Paint cheek = Paint()..color = const Color(0xFFD9A877);
  final Offset head = Offset(w * 0.5, h * 0.5);
  final double r = w * 0.33;

  _drawPastelTile(canvas, size, const Color(0xFFEAF3EC));
  for (final double sign in <double>[-1, 1]) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(head.dx + sign * r * 0.78, head.dy - r * 0.82),
        width: w * 0.13,
        height: h * 0.16,
      ),
      Paint()..color = const Color(0xFF8F6239),
    );
  }
  _bust(canvas, size, const Color(0xFFB98A5E));
  canvas.drawCircle(head, r, body);
  for (final double sign in <double>[-1, 1]) {
    canvas.drawOval(
      Rect.fromCenter(
        center: head.translate(sign * r * 0.5, r * 0.26),
        width: r * 0.58,
        height: r * 0.46,
      ),
      cheek,
    );
  }
  canvas.drawOval(
    Rect.fromCenter(
      center: head.translate(0, r * 0.3),
      width: r * 0.62,
      height: r * 0.48,
    ),
    cheek,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: head.translate(0, r * 0.14),
      width: r * 0.15,
      height: r * 0.11,
    ),
    Paint()..color = const Color(0xFF5C4032),
  );
  paintMascotFace(canvas, head, r, pack, mood, blush: const Color(0xFFF0C9A0));
}

void paintMascotSeaOtter(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
  final double w = size.width;
  final double h = size.height;
  final Paint headFur = Paint()..color = const Color(0xFFC9A076);
  final Offset head = Offset(w * 0.5, h * 0.48);
  final double r = w * 0.32;
  final bool happy = mood != MascotMood.idle;

  _drawPastelTile(canvas, size, const Color(0xFFE7F0F4));
  for (final double sign in <double>[-1, 1]) {
    canvas.drawCircle(
      Offset(head.dx + sign * r * 0.85, head.dy - r * 0.78),
      w * 0.05,
      headFur,
    );
  }
  _bust(canvas, size, const Color(0xFFA87B54));
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.94),
      width: w * 0.56,
      height: h * 0.24,
    ),
    Paint()..color = const Color(0xFFEAD7BE),
  );
  if (happy) {
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.985),
      w * 0.085,
      Paint()..color = const Color(0xFFB9C4C9),
    );
  }
  canvas.drawCircle(head, r, headFur);
  canvas.drawOval(
    Rect.fromCenter(
      center: head.translate(0, r * 0.34),
      width: r * 0.98,
      height: r * 0.64,
    ),
    Paint()..color = const Color(0xFFEAD7BE),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: head.translate(0, r * 0.12),
      width: r * 0.15,
      height: r * 0.11,
    ),
    Paint()..color = const Color(0xFF6E4B2F),
  );
  final Paint dot = Paint()..color = kMascotInk;
  for (final double sign in <double>[-1, 1]) {
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(head.dx + sign * r * (0.6 + i * 0.075), head.dy + r * (0.34 + i * 0.085)),
        w * 0.008,
        dot,
      );
    }
  }
  paintMascotFace(canvas, head, r, pack, mood, blush: const Color(0xFFF0C9A0));
}
