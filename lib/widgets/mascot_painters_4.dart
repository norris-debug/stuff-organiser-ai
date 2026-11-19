import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_face.dart';
import 'mascot_widget.dart';

  void paintMascotCake(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
    final double w = size.width;
    final double h = size.height;
    final Paint body = Paint()..color = pack.accent;
    final Paint icing = Paint()..color = pack.seed;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, h * 0.68), width: w * 0.58, height: h * 0.3),
        Radius.circular(w * 0.06),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, h * 0.5), width: w * 0.44, height: h * 0.2),
        Radius.circular(w * 0.06),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, h * 0.42), width: w * 0.46, height: h * 0.08),
        Radius.circular(w * 0.04),
      ),
      icing,
    );
    canvas.drawCircle(Offset(w / 2, h * 0.3), w * 0.05, icing);
    paintMascotFace(canvas, Offset(w / 2, h * 0.6), w * 0.16, pack, mood);
  }

  void paintMascotSalad(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
    final double w = size.width;
    final double h = size.height;
    final Paint bowl = Paint()..color = pack.accent;
    final Paint leaf = Paint()..color = pack.seed;

    canvas.drawArc(
      Rect.fromCenter(center: Offset(w / 2, h * 0.55), width: w * 0.72, height: h * 0.5),
      0,
      math.pi,
      true,
      bowl,
    );
    for (final double dx in <double>[-0.22, -0.05, 0.12, 0.26]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * (0.5 + dx), h * 0.4),
          width: w * 0.16,
          height: h * 0.13,
        ),
        leaf,
      );
    }
    canvas.drawCircle(Offset(w * 0.42, h * 0.44), w * 0.04, bowl);
    canvas.drawCircle(Offset(w * 0.6, h * 0.42), w * 0.035, bowl);
    paintMascotFace(canvas, Offset(w / 2, h * 0.56), w * 0.15, pack, mood);
  }

  void paintMascotPizza(Canvas canvas, Size size, ThemePack pack, MascotMood mood) {
    final double w = size.width;
    final double h = size.height;
    final Paint crust = Paint()..color = pack.accent;
    final Paint cheese = Paint()..color = pack.seed;

    final Path slice = Path()
      ..moveTo(w / 2, h * 0.2)
      ..lineTo(w * 0.2, h * 0.78)
      ..lineTo(w * 0.8, h * 0.78)
      ..close();
    canvas.drawPath(slice, cheese);
    final Path rim = Path()
      ..moveTo(w * 0.2, h * 0.78)
      ..quadraticBezierTo(w / 2, h * 0.86, w * 0.8, h * 0.78)
      ..lineTo(w * 0.76, h * 0.72)
      ..quadraticBezierTo(w / 2, h * 0.79, w * 0.24, h * 0.72)
      ..close();
    canvas.drawPath(rim, crust);
    for (final Offset spot in const <Offset>[
      Offset(0.5, 0.36),
      Offset(0.4, 0.56),
      Offset(0.6, 0.56),
    ]) {
      canvas.drawCircle(Offset(w * spot.dx, h * spot.dy), w * 0.05, crust);
    }
    paintMascotFace(canvas, Offset(w / 2, h * 0.5), w * 0.12, pack, mood);
  }
