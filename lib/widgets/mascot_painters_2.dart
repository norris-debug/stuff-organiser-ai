import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'mascot_path_data.dart';
import 'mascot_widget.dart';

/// v0.8.8: ramen and berry render from Leaf's traced geometry (path
/// pack v1) through the shared traced renderer - the locked single-
/// expression look, pastel tile still coded at render time. v0.8.12:
/// the happy mood renders Leaf's mouth overrides; other moods keep the
/// locked look. Note and speaker moved unchanged to
/// mascot_painters_legacy.dart (music pack is retired).

void paintMascotRamen(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'ramen', pastel: const Color(0xFFF2EEE4), happy: mood == MascotMood.happy);

void paintMascotBerry(Canvas canvas, Size size, ThemePack pack, MascotMood mood) =>
    paintMascotTraced(canvas, size, 'berry', pastel: const Color(0xFFFBE7EE), happy: mood == MascotMood.happy);
