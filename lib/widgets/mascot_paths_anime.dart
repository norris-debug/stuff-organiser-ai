import 'mascot_path_data.dart';

import 'mascot_paths_1.dart';
import 'mascot_paths_2.dart';
import 'mascot_paths_6.dart';
import 'mascot_paths_7.dart';
import 'mascot_paths_8.dart';
import 'mascot_paths_9.dart';
import 'mascot_paths_10.dart';
import 'mascot_paths_11.dart';
import 'mascot_paths_12.dart';
import 'mascot_paths_13.dart';
import 'mascot_paths_14.dart';
import 'mascot_paths_15.dart';
import 'mascot_paths_16.dart';
import 'mascot_paths_17.dart';
import 'mascot_paths_18.dart';
import 'mascot_paths_19.dart';
import 'mascot_paths_20.dart';
import 'mascot_paths_21.dart';

// v0.8.31: anime pack library (pack rev 6 wiring). Leaf's r6 crown
// and hair data arrived as chunk constants in mascot_paths_9..21
// (dense 1px-sampled clips plus the blindfolded appends). This
// library concatenates the chunk constants into the full *D strings
// and rebuilds the five anime lists from the shipped base rows,
// touching only the rows that differ in pack rev 6. Row indices
// verified against the pack: anime_straw_hat idx 0 (d-only
// replacement), anime_twin_tails idx 17 (d-only), anime_glasses_boy
// idx 16 (d-only), anime_bob_cut idx 16 (d-only), anime_blindfolded
// idx 12+13 (appends). Unchanged rows are referenced by index from
// the base lists so happy-override indices stay valid. Pastel tiles
// stay coded at render time; transparent background.

const String kAnimeStrawHatHairD = kAnimeStrawHatHairP1 +
    kAnimeStrawHatHairP2 +
    kAnimeStrawHatHairP3 +
    kAnimeStrawHatHairP4;

const String kAnimeTwinTailsHairD =
    kAnimeTwinTailsHairP1 + kAnimeTwinTailsHairP2;

const String kAnimeGlassesHairD =
    kAnimeGlassesHairP1 + kAnimeGlassesHairP2 + kAnimeGlassesHairP3;

const String kAnimeBobCutHairD =
    kAnimeBobCutHairP1 + kAnimeBobCutHairP2;

/// anime_straw_hat rev 6: row 0 (the hair mass) re-clipped to sit
/// under the hat silhouette; every other row byte-identical to the
/// shipped base.
final List<MascotShapeRow> kTracedStrawHatR6 = <MascotShapeRow>[
  MascotShapeRow('#4A3230', 1.0, kAnimeStrawHatHairD),
  kTracedStrawHat[1],
  kTracedStrawHat[2],
  kTracedStrawHat[3],
  kTracedStrawHat[4],
  kTracedStrawHat[5],
  kTracedStrawHat[6],
  kTracedStrawHat[7],
  kTracedStrawHat[8],
  kTracedStrawHat[9],
  kTracedStrawHat[10],
  kTracedStrawHat[11],
  kTracedStrawHat[12],
  kTracedStrawHat[13],
  kTracedStrawHat[14],
];

/// anime_twin_tails rev 6: row 17 (the rev-4 crown band) replaced by
/// the dense hair-crown lobe set; rows 0-16 byte-identical to the
/// shipped base.
final List<MascotShapeRow> kTracedTwinTailsR6 = <MascotShapeRow>[
  kTracedTwinTails[0],
  kTracedTwinTails[1],
  kTracedTwinTails[2],
  kTracedTwinTails[3],
  kTracedTwinTails[4],
  kTracedTwinTails[5],
  kTracedTwinTails[6],
  kTracedTwinTails[7],
  kTracedTwinTails[8],
  kTracedTwinTails[9],
  kTracedTwinTails[10],
  kTracedTwinTails[11],
  kTracedTwinTails[12],
  kTracedTwinTails[13],
  kTracedTwinTails[14],
  kTracedTwinTails[15],
  kTracedTwinTails[16],
  MascotShapeRow('#5A4640', 1.0, kAnimeTwinTailsHairD),
];

/// anime_glasses_boy rev 6: row 16 (the rev-4 crown band) replaced by
/// the dense hair-crown clip; rows 0-15 byte-identical to the shipped
/// base.
final List<MascotShapeRow> kTracedGlassesBoyR6 = <MascotShapeRow>[
  kTracedGlassesBoy[0],
  kTracedGlassesBoy[1],
  kTracedGlassesBoy[2],
  kTracedGlassesBoy[3],
  kTracedGlassesBoy[4],
  kTracedGlassesBoy[5],
  kTracedGlassesBoy[6],
  kTracedGlassesBoy[7],
  kTracedGlassesBoy[8],
  kTracedGlassesBoy[9],
  kTracedGlassesBoy[10],
  kTracedGlassesBoy[11],
  kTracedGlassesBoy[12],
  kTracedGlassesBoy[13],
  kTracedGlassesBoy[14],
  kTracedGlassesBoy[15],
  MascotShapeRow('#3A3230', 1.0, kAnimeGlassesHairD),
];

/// anime_bob_cut rev 6: row 16 (the rev-4 crown fill band) replaced
/// by the dense hair-crown clip; rows 0-15 byte-identical to the
/// shipped base.
final List<MascotShapeRow> kTracedBobCutR6 = <MascotShapeRow>[
  kTracedBobCut[0],
  kTracedBobCut[1],
  kTracedBobCut[2],
  kTracedBobCut[3],
  kTracedBobCut[4],
  kTracedBobCut[5],
  kTracedBobCut[6],
  kTracedBobCut[7],
  kTracedBobCut[8],
  kTracedBobCut[9],
  kTracedBobCut[10],
  kTracedBobCut[11],
  kTracedBobCut[12],
  kTracedBobCut[13],
  kTracedBobCut[14],
  kTracedBobCut[15],
  MascotShapeRow('#7A4A3A', 1.0, kAnimeBobCutHairD),
];

/// anime_blindfolded rev 6: two appended rows on top of the shipped
/// base (thickened blindfold band + hair-white half fill); rows 0-11
/// byte-identical to the shipped base.
final List<MascotShapeRow> kTracedBlindfoldedR6 = <MascotShapeRow>[
  kTracedBlindfolded[0],
  kTracedBlindfolded[1],
  kTracedBlindfolded[2],
  kTracedBlindfolded[3],
  kTracedBlindfolded[4],
  kTracedBlindfolded[5],
  kTracedBlindfolded[6],
  kTracedBlindfolded[7],
  kTracedBlindfolded[8],
  kTracedBlindfolded[9],
  kTracedBlindfolded[10],
  kTracedBlindfolded[11],
  MascotShapeRow('#3A3230', 1.0, kAnimeBlindfoldedAppend1),
  MascotShapeRow('#F2F2F0', 1.0, kAnimeBlindfoldedAppend2),
];
