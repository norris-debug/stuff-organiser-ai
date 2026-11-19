import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_path_data.dart';
import 'mascot_widget.dart';

/// v0.8.8: bunny and cat render from Leaf's traced geometry (path pack
/// v1) through the shared traced renderer - the locked single-expression
/// look, pastel tile still coded at render time. Mood variants are a
/// fast-follow traced set. Robot and axolotl moved unchanged to
/// mascot_painters_legacy.dart (not selectable since v0.6.8).

void paintMascotBunny(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'bunny', pastel: const Color(0xFFFBE7EE));

void paintMascotCat(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'cat', pastel: const Color(0xFFF2EEE4));
