import 'package:flutter/material.dart';

import 'mascot_happy_overrides.dart';
import 'mascot_paths_1.dart';
import 'mascot_paths_2.dart';
import 'mascot_paths_3.dart';
import 'mascot_paths_4.dart';
import 'mascot_paths_5.dart';
import 'mascot_paths_6.dart';
import 'mascot_paths_7.dart';
import 'mascot_paths_8.dart';
import 'mascot_paths_anime.dart';

class MascotShapeRow {
  const MascotShapeRow(this.fill, this.opacity, this.d);
  final String fill;
  final double opacity;
  final String d;
}

/// v0.8.8: traced-geometry renderer for Leaf's locked mascot set.
/// Data lives in mascot_paths_*.dart as flat const rows. Path data is
/// absolute M/L/C/Q/Z only, viewBox 0 0 1024 1024, transparent
/// background - the pastel tile stays coded at render time.
final Map<String, List<Path>> _kPathCache = <String, List<Path>>{};
final Map<String, List<Color>> _kFillCache = <String, List<Color>>{};

Path _pathFromD(String d) {
  final Path path = Path();
  int i = 0;
  String cmd = 'M';
  final List<double> take = <double>[];
  while (i < d.length) {
    final String ch = d[i];
    if (ch == 'M' || ch == 'L' || ch == 'C' || ch == 'Q' || ch == 'Z') {
      cmd = ch;
      i++;
      take.clear();
      continue;
    }
    final RegExp num = RegExp(r'^-?[0-9]*\.?[0-9]+');
    final Match? m = num.firstMatch(d.substring(i));
    if (m == null) {
      i++;
      continue;
    }
    take.add(double.parse(m.group(0)!));
    i += m.group(0)!.length;
    int need = 0;
    if (cmd == 'M' || cmd == 'L') need = 2;
    if (cmd == 'C') need = 6;
    if (cmd == 'Q') need = 4;
    if (need > 0 && take.length < need) continue;
    if (cmd == 'M') {
      path.moveTo(take[0], take[1]);
    } else if (cmd == 'L') {
      path.lineTo(take[0], take[1]);
    } else if (cmd == 'C') {
      path.cubicTo(take[0], take[1], take[2], take[3], take[4], take[5]);
    } else if (cmd == 'Q') {
      path.quadraticBezierTo(take[0], take[1], take[2], take[3]);
    } else if (cmd == 'Z') {
      path.close();
    }
    if (need > 0) take.removeRange(0, need);
  }
  return path;
}

Color _fillFromHex(String hex) {
  final String digits = hex.replaceAll('#', '').trim();
  return Color(0xFF000000 | int.parse(digits, radix: 16));
}

/// Paints one traced mascot: optional pastel tile, then every traced
/// shape scaled from the 1024 viewBox into the widget square. With
/// happy=true the mouth shape(s) listed in kHappyOverrides replace
/// their base rows; every other mood keeps the shipped base list.
void paintMascotTraced(
  Canvas canvas,
  Size size,
  String mascotName, {
  Color? pastel,
  bool happy = false,
}) {
  List<MascotShapeRow> shapeRows =
      kTracedMascots[mascotName] ?? const <MascotShapeRow>[];
  if (shapeRows.isEmpty) {
    return;
  }
  final Map<int, MascotShapeRow>? overrides =
      happy ? kHappyOverrides[mascotName] : null;
  String cacheKey = mascotName;
  if (overrides != null && overrides.isNotEmpty) {
    shapeRows = <MascotShapeRow>[
      for (int i = 0; i < shapeRows.length; i++) overrides[i] ?? shapeRows[i],
    ];
    cacheKey = '$mascotName#happy';
  }
  if (pastel != null) {
    canvas.drawRect(Offset.zero & size, Paint()..color = pastel);
  }
  final List<Path> paths = _kPathCache.putIfAbsent(
    cacheKey,
    () => <Path>[for (final MascotShapeRow row in shapeRows) _pathFromD(row.d)],
  );
  final List<Color> fills = _kFillCache.putIfAbsent(
    cacheKey,
    () => <Color>[
      for (final MascotShapeRow row in shapeRows)
        _fillFromHex(row.fill).withAlpha((row.opacity.clamp(0.0, 1.0) * 255).round()),
    ],
  );
  canvas.save();
  canvas.scale(size.width / 1024, size.height / 1024);
  for (int i = 0; i < paths.length; i++) {
    canvas.drawPath(paths[i], Paint()..color = fills[i]);
  }
  canvas.restore();
}

const Map<String, List<MascotShapeRow>> kTracedMascots = <String, List<MascotShapeRow>>{
  'bunny': kTracedBunny,
  'cat': kTracedCat,
  'red_panda': kTracedRedPanda,
  'quokka': kTracedQuokka,
  'sea_otter': kTracedSeaOtter,
  'ramen': kTracedRamen,
  'berry': kTracedBerry,
  'cake': kTracedCake,
  'salad': kTracedSalad,
  'pizza': kTracedPizza,
  'anime_blindfolded': kTracedBlindfoldedR6,
  'anime_straw_hat': kTracedStrawHatR6,
  'anime_twin_tails': kTracedTwinTailsR6,
  'anime_glasses_boy': kTracedGlassesBoyR6,
  'anime_bob_cut': kTracedBobCutR6,
};
