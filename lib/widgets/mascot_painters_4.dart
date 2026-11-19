import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_path_data.dart';
import 'mascot_widget.dart';

/// v0.8.8: cake, salad and pizza render from Leaf's traced geometry
/// (path pack v1) through the shared traced renderer - the locked
/// single-expression look, per-mascot pastel tile still coded at render
/// time. Mood variants are a fast-follow traced set.

void paintMascotCake(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'cake', pastel: const Color(0xFFFBEFDD));

void paintMascotSalad(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'salad', pastel: const Color(0xFFEAF3EC));

void paintMascotPizza(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'pizza', pastel: const Color(0xFFE7F0F4));
