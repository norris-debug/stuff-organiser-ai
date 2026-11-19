import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mascot variants. v1 uses painted placeholder art only (no image assets).
enum MascotVariant { bunny, cat, robot, axolotl, ramen, berry, note, speaker, redPanda, quokka, seaOtter, cake, salad, pizza, blindfolded, strawHat, ninja, idol, mage }

extension MascotVariantX on MascotVariant {
  String get label => switch (this) {
        MascotVariant.bunny => 'Bunny',
        MascotVariant.cat => 'Cat',
        MascotVariant.robot => 'Robot',
        MascotVariant.axolotl => 'Axolotl',
        MascotVariant.ramen => 'Ramen',
        MascotVariant.berry => 'Berry',
        MascotVariant.note => 'Note',
        MascotVariant.speaker => 'Speaker',
        MascotVariant.redPanda => 'Red Panda',
        MascotVariant.quokka => 'Quokka',
        MascotVariant.seaOtter => 'Sea Otter',
        MascotVariant.cake => 'Cake',
        MascotVariant.salad => 'Salad',
        MascotVariant.pizza => 'Pizza',
        MascotVariant.blindfolded => 'Blindfolded',
        MascotVariant.strawHat => 'Straw Hat',
        MascotVariant.ninja => 'Ninja',
        MascotVariant.idol => 'Idol',
        MascotVariant.mage => 'Mage',
      };
}

/// A theme pack = colour palette + the mascots that belong to it.
class ThemePack {
  const ThemePack({
    required this.id,
    required this.label,
    required this.emoji,
    required this.seed,
    required this.accent,
    required this.mascots,
  });

  final String id;
  final String label;
  final String emoji;
  final Color seed;
  final Color accent;
  final List<MascotVariant> mascots;
}

const List<ThemePack> themePacks = <ThemePack>[
  ThemePack(
    id: 'anime',
    label: 'Anime',
    emoji: '🌸',
    seed: Color(0xFF7C4DFF),
    accent: Color(0xFFFF8A65),
    mascots: <MascotVariant>[
      MascotVariant.blindfolded,
      MascotVariant.strawHat,
      MascotVariant.ninja,
      MascotVariant.idol,
      MascotVariant.mage,
    ],
  ),
  ThemePack(
    id: 'animals',
    label: 'Animals',
    emoji: '🐾',
    seed: Color(0xFF2E7D32),
    accent: Color(0xFF9CCC65),
    mascots: <MascotVariant>[
      MascotVariant.cat,
      MascotVariant.axolotl,
      MascotVariant.redPanda,
      MascotVariant.quokka,
      MascotVariant.seaOtter,
    ],
  ),
  ThemePack(
    id: 'food',
    label: 'Food',
    emoji: '🍜',
    seed: Color(0xFFE65100),
    accent: Color(0xFFFFB300),
    mascots: <MascotVariant>[
      MascotVariant.ramen,
      MascotVariant.berry,
      MascotVariant.cake,
      MascotVariant.salad,
      MascotVariant.pizza,
    ],
  ),
];

ThemePack themePackById(String id) =>
    themePacks.firstWhere((ThemePack pack) => pack.id == id, orElse: () => themePacks.first);

ThemeData buildAppTheme(ThemePack pack) {
  final ColorScheme scheme = ColorScheme.fromSeed(seedColor: pack.seed);
  final TextTheme base = ThemeData.light().textTheme;
  final TextTheme textTheme = base.copyWith(
    headlineMedium: GoogleFonts.baloo2(fontSize: 30, fontWeight: FontWeight.w700),
    headlineSmall: GoogleFonts.baloo2(fontSize: 32, fontWeight: FontWeight.w700),
    titleLarge: GoogleFonts.baloo2(fontSize: 26, fontWeight: FontWeight.w700),
    titleMedium: GoogleFonts.baloo2(fontSize: 19, fontWeight: FontWeight.w700),
    titleSmall: GoogleFonts.baloo2(fontSize: 16, fontWeight: FontWeight.w700),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
    ),
  );
}
