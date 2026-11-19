import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_path_data.dart';
import 'mascot_widget.dart';

/// v0.8.8: blindfolded and straw hat render from Leaf's traced geometry
/// (path pack v1) through the shared traced renderer - the locked
/// single-expression look, no baked tile (the anime pack paints on the
/// shared background, pastels stay coded elsewhere). Mood variants are
/// a fast-follow traced set. Ninja, idol and mage moved unchanged to
/// mascot_painters_legacy.dart pending the locked anime-three swap.

void paintMascotBlindfolded(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'anime_blindfolded');

void paintMascotStrawHat(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'anime_straw_hat');
