part of 'scan_flow.dart';

int _photosSeed(List<_PhotoItem> photos) {
  int seed = 7;
  for (final _PhotoItem photo in photos) {
    final Uint8List bytes = photo.bytes;
    final int end = bytes.length < 2048 ? bytes.length : 2048;
    for (int i = 0; i < end; i++) {
      seed = (seed * 31 + bytes[i]) % 0x7FFFFFFF;
    }
  }
  return seed;
}

_ScanPlan _demoPlan(List<_PhotoItem> photos, String notes) {
  final int seed = _photosSeed(photos);
  final _DemoBank bank = _demoBanks[seed % _demoBanks.length];
  final int offset = seed % bank.suggestions.length;
  final List<_Suggestion> rotated = <_Suggestion>[
    ...bank.suggestions.skip(offset),
    ...bank.suggestions.take(offset),
  ];
  final int count = 2 + (seed % 3);
  // The demo coach cannot see the photos, so the two room-shape actions
  // that used to repeat on every run (fold the clothes, clear the floor)
  // now only join the plan when the user's own notes mention them.
  final String lowerNotes = notes.toLowerCase();
  final bool wantsClothes = <String>[
    'clothes',
    'clothing',
    'shirt',
    'pants',
    'laundry',
    'wardrobe',
    'jacket',
    'sock',
  ].any(lowerNotes.contains);
  final bool wantsFloor = <String>[
    'floor',
    'ground',
    'walking lane',
    'walkway',
  ].any(lowerNotes.contains);
  final List<_Suggestion> filtered = <_Suggestion>[
    for (final _Suggestion suggestion in rotated)
      if ((wantsClothes ||
              suggestion.title !=
                  'Fold the clothes and line them up in one stack') &&
          (wantsFloor ||
              suggestion.title !=
                  'Clear the floor into one walking lane'))
        suggestion,
  ];
  final List<String> observations = List<String>.of(bank.observations);
  observations.insert(
    0,
    'Before anything else, for each item ask: do I need, use and love '
    'this right now. Whatever fails all three goes to the donate or bin '
    'pile before any organising starts.',
  );
  if (notes.trim().isNotEmpty) {
    observations.add(
      'Your notes are in: the plan below also covers the things you '
      'described that the photos cannot show.',
    );
  }
  return _ScanPlan(
    observations: observations,
    suggestions: filtered.take(count).toList(),
    habits: bank.habits,
  );
}
