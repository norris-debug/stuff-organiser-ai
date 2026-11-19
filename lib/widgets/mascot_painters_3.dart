import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_path_data.dart';
import 'mascot_widget.dart';

/// v0.8.8: red panda, quokka and sea otter render from Leaf's traced
/// geometry (path pack v1) through the shared traced renderer - the
/// locked single-expression look, per-mascot pastel tile still coded at
/// render time. Mood variants are a fast-follow traced set.

void paintMascotRedPanda(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'red_panda', pastel: const Color(0xFFFBEFDD));

void paintMascotQuokka(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'quokka', pastel: const Color(0xFFEAF3EC));

void paintMascotSeaOtter(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'sea_otter', pastel: const Color(0xFFE7F0F4));
