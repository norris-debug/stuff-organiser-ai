part of 'scan_flow.dart';

/// v0.8.5: the coach drafts from the recognition lane object list (label
/// plus confidence per line) instead of a canned script, so the dialogue
/// follows what is actually in the photo. Tier rules per the agreed
/// handoff format: 85%+ confirmed, 50-84% verify, under 50% flagged.
/// The list is pasted into the coach chat on the interim route,
/// mirroring how render slots attach from the lane post-back.
/// v0.8.7: the intake flow itself lives in scan_flow_recognition_flow.dart.
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
/// v0.8.28 (QA R8-F4): parses the pasted recognition list. One line may
/// now carry SEVERAL items - a typed comma/semicolon list ("chair, lamp,
/// box") or several confidence reads on one line ("chair - 92%, lamp
/// - 88%"). Those lines used to parse as ONE label and then hit the
/// 60-character label cap in the per-line body below, silently chopping
/// the line to its first 60 characters - everything after it never
/// reached the plan (Meiosis run, live 0.8.27+47, confirmed ×2,
/// 2026-11-21). Lines with zero or multiple '%' markers split on
/// commas/semicolons and each piece runs through the same per-line
/// parse; the documented lane shape (one object per line, exactly one
/// confidence marker) is byte-identical to the old path.
List<_RecognizedObject> _parseRecognition(String raw) {
  final List<_RecognizedObject> items = <_RecognizedObject>[];
  final Set<String> seen = <String>{};
  for (String line in raw.split('\n')) {
    line = line.trim();
    if (line.length < 3) continue;
    final int pctCount = RegExp('%').allMatches(line).length;
    final bool plainList =
        pctCount == 0 && (line.contains(',') || line.contains(';'));
    if (plainList || pctCount > 1) {
      bool splitAnything = false;
      for (final String piece in line.split(RegExp('[,;]'))) {
        final String trimmed = piece.trim();
        if (trimmed.length < 3) continue;
        _parseRecognitionLine(trimmed, items, seen);
        splitAnything = true;
        if (items.length >= 24) return items;
      }
      // A split that yielded nothing (every piece under three chars)
      // falls through to the whole-line parse so the line is never
      // silently dropped.
      if (splitAnything) continue;
    }
    _parseRecognitionLine(line, items, seen);
    if (items.length >= 24) break;
  }
  return items;
}

/// v0.8.28: the per-line body of [_parseRecognition], unchanged in
/// behavior - one call appends 0 or 1 items and the callers own the
/// 24-item cap.
void _parseRecognitionLine(
  String line,
  List<_RecognizedObject> items,
  Set<String> seen,
) {
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
  final String lower = line.toLowerCase();
  bool skip = false;
  for (final String word in skipStarts) {
    if (lower.startsWith(word)) {
      skip = true;
      break;
    }
  }
  if (skip) return;
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
  if (label.length < 2) return;
  final String key = label.toLowerCase();
  if (seen.contains(key)) return;
  seen.add(key);
  items.add(_RecognizedObject(label, tier));
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

// v0.8.17: the plan drafter (_bucketSuggestion + _recognitionPlan)
// moved to scan_flow_draft.dart - same library, no other changes.