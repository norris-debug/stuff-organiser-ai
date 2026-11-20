import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_path_data.dart';
import 'mascot_widget.dart';

/// v0.8.8: cake, salad and pizza render from Leaf's traced geometry
/// (path pack v1) through the shared traced renderer - the locked
/// single-expression look, per-mascot pastel tile still coded at render
/// time. v0.8.12: the happy mood renders Leaf's mouth overrides; other
/// moods keep the locked look.

void paintMascotCake(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'cake', pastel: const Color(0xFFFBEFDD), happy: mood == MascotMood.happy);

void paintMascotSalad(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'salad', pastel: const Color(0xFFEAF3EC), happy: mood == MascotMood.happy);

void paintMascotPizza(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'pizza', pastel: const Color(0xFFE7F0F4), happy: mood == MascotMood.happy);
