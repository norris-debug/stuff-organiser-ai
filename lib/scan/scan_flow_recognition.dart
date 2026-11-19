part of 'scan_flow.dart';

/// v0.8.5: the coach drafts from the recognition lane object list (label
/// plus confidence per line) instead of a canned script, so the dialogue
/// follows what is actually in the photo. Tier rules per the agreed
/// handoff format: 85%+ confirmed, 50-84% verify, under 50% flagged.
/// The list is pasted into the coach chat on the interim route,
/// mirroring how render slots attach from the lane post-back.
class _RecognizedObject {
  const _RecognizedObject(this.label, this.tier);

  final String label;

  /// 0 confirmed, 1 verify, 2 flagged.
  final int tier;
}

bool _isDigitChar(String c) {
  return c == '0' ||
      c == '1' ||
      c == '2' ||
      c == '3' ||
      c == '4' ||
      c == '5' ||
      c == '6' ||
      c == '7' ||
      c == '8' ||
      c == '9';
}

/// Lenient parser: bullets, numbering, percentages and tier markers are
/// stripped and the label text is kept. Header and ledger lines are
/// skipped. Lines without any confidence signal default to verify tier.
List<_RecognizedObject> _parseRecognition(String raw) {
  final List<_RecognizedObject> items = <_RecognizedObject>[];
  final Set<String> seen = <String>{};
  const List<String> skipStarts = <String>[
    'recognized',
    'recognition',
    'ledger',
    'api call',
    'quota',
    'tier',
    'summary',
    'sandbox',
    'test photo',
    'executive',
    'next action',
    'http',
    'img_',
    'cat.jpg',
  ];
  for (String line in raw.split('\n')) {
    line = line.trim();
    if (line.length < 3) continue;
    final String lower = line.toLowerCase();
    bool skip = false;
    for (final String word in skipStarts) {
      if (lower.startsWith(word)) {
        skip = true;
        break;
      }
    }
    if (skip) continue;
    int tier = 1;
    int cutAt = -1;
    final int pct = line.indexOf('%');
    if (pct > 0) {
      int start = pct;
      while (start > 0 && _isDigitChar(line.substring(start - 1, start))) {
        start--;
      }
      final String digits = line.substring(start, pct);
      final int? value = int.tryParse(digits);
      if (digits.isNotEmpty && value != null) {
        tier = value >= 85 ? 0 : (value >= 50 ? 1 : 2);
        cutAt = start;
      }
    } else if (lower.contains('confirm')) {
      tier = 0;
    } else if (lower.contains('flag') ||
        lower.contains('uncertain') ||
        lower.contains('unsure')) {
      tier = 2;
    }
    String label;
    if (cutAt >= 0) {
      final String head = line.substring(0, cutAt).trim();
      final String tail = line.substring(pct + 1).trim();
      label = head.length >= 2 && head.length >= tail.length ? head : tail;
    } else {
      label = line;
    }
    for (final String wrap in const <String>[
      '(confirmed)',
      '(verify)',
      '(flagged)',
      '(uncertain)',
    ]) {
      if (lower.endsWith(wrap)) {
        label = label.substring(0, label.length - wrap.length);
        break;
      }
    }
    label = label.trim();
    while (label.isNotEmpty) {
      final String c = label.substring(0, 1);
      if (c == '-' ||
          c == '*' ||
          c == '>' ||
          c == ':' ||
          c == ',' ||
          c == '.' ||
          c == '%' ||
          c == '(' ||
          c == '[' ||
          c == ' ') {
        label = label.substring(1);
      } else {
        break;
      }
    }
    while (label.isNotEmpty) {
      final String c = label.substring(label.length - 1);
      if (c == '-' ||
          c == ':' ||
          c == ',' ||
          c == ';' ||
          c == ')' ||
          c == ']' ||
          c == ' ') {
        label = label.substring(0, label.length - 1);
      } else {
        break;
      }
    }
    final String lowerLabel = label.toLowerCase();
    if (lowerLabel.startsWith('confirmed')) {
      label = label.substring(9).trim();
      if (tier == 1) tier = 0;
    } else if (lowerLabel.startsWith('verify')) {
      label = label.substring(6).trim();
    } else if (lowerLabel.startsWith('flagged')) {
      label = label.substring(7).trim();
      if (tier == 1) tier = 2;
    }
    if (label.length > 60) label = label.substring(0, 60).trim();
    if (label.length < 2) continue;
    final String key = label.toLowerCase();
    if (seen.contains(key)) continue;
    seen.add(key);
    items.add(_RecognizedObject(label, tier));
    if (items.length >= 24) break;
  }
  return items;
}

String _joinLabels(List<_RecognizedObject> items) {
  final List<String> labels =
      items.map((_RecognizedObject o) => o.label).toList();
  if (labels.isEmpty) return '';
  if (labels.length == 1) return labels.first;
  return '${labels.sublist(0, labels.length - 1).join(', ')} and ${labels.last}';
}

int _bucketOf(String label) {
  final String l = label.toLowerCase();
  bool has(List<String> words) {
    for (final String word in words) {
      if (l.contains(word)) return true;
    }
    return false;
  }

  if (has(<String>[
    'paper',
    'document',
    'folder',
    'notebook',
    'envelope',
    'receipt',
    'mail',
    'bill',
    'file',
  ])) {
    return 0;
  }
  if (has(<String>[
    'clothes',
    'clothing',
    'shirt',
    'pant',
    'sock',
    'jacket',
    'laundry',
    'wear',
    'dress',
    'scarf',
    'hat',
  ])) {
    return 1;
  }
  if (has(<String>[
    'cup',
    'mug',
    'plate',
    'bowl',
    'dish',
    'glass',
    'bottle',
    'cutlery',
    'fork',
    'spoon',
    'knife',
  ])) {
    return 2;
  }
  if (has(<String>[
    'cable',
    'charger',
    'wire',
    'phone',
    'laptop',
    'tablet',
    'camera',
    'electronic',
    'plug',
    'device',
    'remote',
  ])) {
    return 3;
  }
  if (has(<String>[
    'box',
    'container',
    'basket',
    'bin',
    'case',
    'bag',
    'tray',
    'jar',
    'tin',
  ])) {
    return 4;
  }
  if (has(<String>['book', 'magazine', 'comic', 'manual'])) {
    return 5;
  }
  if (has(<String>['toy', 'game', 'puzzle', 'figure', 'doll'])) {
    return 6;
  }
  return 7;
}

_Suggestion _bucketSuggestion(int bucket, List<_RecognizedObject> items) {
  final String labels = _joinLabels(items);
  switch (bucket) {
    case 0:
      return _Suggestion(
        title: 'Give the $labels one pass: act, file or recycle',
        detail:
            'Paper only has three honest destinations. Hold each sheet and '
            'ask the three questions - anything that fails them goes out '
            'before any filing starts.',
        steps: <String>[
          'Gather every sheet into one pile on a clear spot.',
          'Split it into action, file and recycle.',
          'Recycle the third pile today, then file the keepers in one labelled folder.',
        ],
      );
    case 1:
      return _Suggestion(
        title: 'Fold the $labels into one stack',
        detail:
            'Folded and lined up, the same clothes take half the space and '
            'stop the pile from growing back.',
        steps: <String>[
          'Pull the items out and send anything worn-out straight to the donate pile.',
          'Fold each keeper and line the stack up in wear order.',
          'Give the stack one fixed home - a shelf or a drawer, not a chair.',
        ],
      );
    case 2:
      return _Suggestion(
        title: 'Wash and home the $labels in one batch',
        detail:
            'One batch beats sorting dirty from clean, and everything gets '
            'one shelf it always returns to.',
        steps: <String>[
          'Collect the items into one group by the sink.',
          'Wash them in a single batch and dry them together.',
          'Home them in one spot, everyday pieces at the front.',
        ],
      );
    case 3:
      return _Suggestion(
        title: 'Coil the $labels into one labelled box',
        detail:
            'Tangled cables eat surface space and vanish when needed. One '
            'box, one label, one drawer.',
        steps: <String>[
          'Untangle everything and set aside what no longer works.',
          'Coil each keeper and band it.',
          'Box them, label the front, and give the box one drawer.',
        ],
      );
    case 4:
      return _Suggestion(
        title: 'Sort the $labels down to the keepers',
        detail:
            'Containers multiply quietly. Keep the ones you actually use '
            'and let the rest go without guilt.',
        steps: <String>[
          'Empty each one and match lids to bodies.',
          'Keep the pairs that get used; donate or bin the rest.',
          'Nest the keepers and store them near where they are used.',
        ],
      );
    case 5:
      return _Suggestion(
        title: 'Shelve the $labels upright in one row',
        detail:
            'Upright books use height instead of depth and you can see '
            'every title at a glance.',
        steps: <String>[
          'Take them all down and let go of the ones you will not read again.',
          'Shelve the keepers upright, tallest at the side.',
          'Leave a little space at the end so the row can breathe.',
        ],
      );
    case 6:
      return _Suggestion(
        title: 'Give the $labels one home',
        detail:
            'Toys without a home always end up back on the floor. One box '
            'per kind fixes it.',
        steps: <String>[
          'Gather them and set aside anything broken.',
          'Sort the keepers by kind into one box each.',
          'Put the boxes on one low shelf you can reach.',
        ],
      );
    default:
      return _Suggestion(
        title: 'Give the $labels one home',
        detail:
            'Hold each one and ask: do I need it, use it, love it? Whatever '
            'fails all three has served its purpose - let it go.',
        steps: <String>[
          'Group the items by where they belong.',
          'Donate or bin the ones that fail the three questions.',
          'Give every keeper a fixed home, one touch away.',
        ],
      );
  }
}

/// Builds the coach plan from the recognized object list. Observations
/// name the actual items with tier-honest wording, suggestions come from
/// the biggest work buckets, and the Danshari opener leads.
_ScanPlan _recognitionPlan(List<_RecognizedObject> items, String notes) {
  final List<_RecognizedObject> confirmed = <_RecognizedObject>[];
  final List<_RecognizedObject> verify = <_RecognizedObject>[];
  final List<_RecognizedObject> flagged = <_RecognizedObject>[];
  for (final _RecognizedObject item in items) {
    if (item.tier == 0) {
      confirmed.add(item);
    } else if (item.tier == 2) {
      flagged.add(item);
    } else {
      verify.add(item);
    }
  }
  final int total = items.length;
  final List<String> observations = <String>[
    'Before anything else, for each item ask: do I need, use and love '
        'this right now. Whatever fails all three goes to the donate or bin '
        'pile before any organising starts.',
  ];
  if (confirmed.isNotEmpty) {
    observations
        .add('Straight from your scan, I can see: ${_joinLabels(confirmed)}.');
    final int pick = total % 3;
    if (pick == 0) {
      observations.add(
          'Each of those is sitting out with no fixed home yet - that is '
          'the first thing to fix.');
    } else if (pick == 1) {
      observations.add(
          'They are visible clutter right now, which is good news: visible '
          'means sortable in one session.');
    } else {
      observations.add(
          'None of those needs a purchase or a project - just decisions '
          'and one home each.');
    }
  }
  if (verify.isNotEmpty) {
    observations.add(
        'I think I can also see ${_joinLabels(verify)} - double-check '
        'those for me before we plan around them.');
  }
  if (flagged.isNotEmpty) {
    observations.add(
        'A few reads were too unsure to act on: ${_joinLabels(flagged)}. '
        'Tell me what they actually are and I will fold them in.');
  }
  if (notes.trim().isNotEmpty) {
    observations.add(
        'Your notes are in: the plan below also covers the things you '
        'described that the photos cannot show.');
  }
  final Map<int, List<_RecognizedObject>> buckets =
      <int, List<_RecognizedObject>>{};
  for (final _RecognizedObject item in items) {
    final int bucket = _bucketOf(item.label);
    buckets.putIfAbsent(bucket, () => <_RecognizedObject>[]).add(item);
  }
  final List<int> order = buckets.keys.toList();
  order.sort((int a, int b) => buckets[b]!.length.compareTo(buckets[a]!.length));
  final List<_Suggestion> suggestions = <_Suggestion>[];
  final int wanted = total <= 3 ? 2 : 3;
  for (final int bucket in order) {
    if (suggestions.length >= wanted) break;
    suggestions.add(_bucketSuggestion(bucket, buckets[bucket]!));
  }
  if (suggestions.isEmpty) {
    suggestions.add(_bucketSuggestion(7, items));
  }
  if (suggestions.length == 1) {
    suggestions.add(const _Suggestion(
      title: 'Clear one surface down to zero',
      detail:
          'Pick one flat surface and leave it completely empty. A clear '
          'surface is the fastest reset a room has.',
      steps: <String>[
        'Sweep everything off it into one pile.',
        'Sort the pile: home, relocate or donate.',
        'Wipe it down and keep only what truly lives there.',
      ],
    ));
  }
  return _ScanPlan(
    observations: observations,
    suggestions:
        suggestions.length > 4 ? suggestions.sublist(0, 4) : suggestions,
    habits: const <String>[
      'One in, one out - a new item replaces an old one.',
      'Keep everyday things one touch away from where they are used.',
      'Clear the surface before you leave the room.',
    ],
    tidiness: total <= 2 ? 'tidy' : (total <= 8 ? 'moderate' : 'messy'),
  );
}
