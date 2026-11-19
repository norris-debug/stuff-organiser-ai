import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_path_data.dart';
import 'mascot_widget.dart';

/// v0.8.8: blindfolded and straw hat render from Leaf's traced geometry
/// (path pack v1) through the shared traced renderer - the locked
/// single-expression look, no baked tile (the anime pack paints on the
/// shared background, pastels stay coded elsewhere). Mood variants are
/// a fast-follow traced set.
/// v0.8.9: the anime three swapped in - twin tails, glasses boy and bob
/// cut render from the same traced pack; the ninja/idol/mage alternates
/// are retired from the picker.

void paintMascotBlindfolded(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'anime_blindfolded');

void paintMascotStrawHat(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'anime_straw_hat');

void paintMascotTwinTails(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'anime_twin_tails');

void paintMascotGlassesBoy(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'anime_glasses_boy');

void paintMascotBobCut(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'anime_bob_cut');
