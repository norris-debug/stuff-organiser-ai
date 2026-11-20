/// Coach vocabulary pools (v0.8.17).
///
/// The Coach's Chat read repetitive after a few runs because three sites
/// drafted from fixed template strings: the plan drafter, the bucket
/// suggestions and the chat assembly. This library owns the wording
/// pools and the no-repeat picker all three share. The Danshari backbone
/// (need, use and love first, then the Dan, Sha and Ri gates) stays the
/// method - only the wording rotates.
///
/// Determinism: picks are seeded from the scan id and a turn counter, so
/// one conversation stays coherent while different scans read
/// differently. Consecutive picks from the same pool never repeat while
/// the pool holds more than one entry.

/// Rotating opener lines for coach turns.
const List<String> kCoachOpeners = <String>[
  "Here is what stands out.",
  "Let me start with the biggest thing.",
  "One spot in your space leads the list.",
  "Your photos tell a clear story.",
  "First impressions from this scan.",
  "There is one area to face first.",
];

/// Interjection lines the coach drops between longer turns.
const List<String> kCoachInterjections = <String>[
  "Makes sense.",
  "That one I can do right now.",
  "Good tip.",
  "Noted, next one.",
  "Okay, next.",
  "Fair point.",
  "On it.",
  "That tracks.",
  "Easy win.",
  "Keeping that in mind.",
];

/// Lead-in phrases for reading an observation aloud.
const List<String> kObservationLeads = <String>[
  "I can see",
  "The photos show",
  "What stands out is",
  "Right away, I notice",
  "The scan picks up",
  "One thing reads clearly:",
];

/// Verbs for suggesting a discard, rotated per item.
const List<String> kDiscardVerbs = <String>[
  "could be ready to let go",
  "has likely served its purpose",
  "might not need to stay",
  "is a candidate to release",
  "could move out first",
  "may be worth parting with",
];

/// Phrases for suggesting an item stays.
const List<String> kKeepPhrases = <String>[
  "earns its place",
  "looks like a daily companion",
  "seems to belong here",
  "is doing real work for you",
  "fits how the space is used",
];

/// Question forms for coach confirmation points.
const List<String> kConfirmationQuestions = <String>[
  "Does this one still earn its spot?",
  "When did you last reach for it?",
  "If it left today, would you miss it?",
  "Is it serving the room, or filling it?",
  "Would you buy it again this week?",
];

/// Dan gate phrasings: the joy check comes first.
const List<String> kDanPhrases = <String>[
  "the joy check comes first",
  "ask whether it still sparks anything",
  "start with the joy question",
];

/// Sha gate phrasings: needed now, or only someday.
const List<String> kShaPhrases = <String>[
  "then the use check: needed now or someday",
  "next, does it earn its keep this season",
  "then ask how often it is really used",
];

/// Ri gate phrasings: everything that stays gets one home.
const List<String> kRiPhrases = <String>[
  "finally, give what stays one clear home",
  "last, everything left needs one address",
  "then set one home per survivor",
];

/// Sentence forms a coach turn can take.
enum CoachTurnForm { opener, observation, question, suggestion, interjection }

/// No-repeat picker over one pool. Seeded and deterministic, and it never
/// returns the same entry twice in a row while the pool allows it.
class VocabPicker {
  VocabPicker({required int seed})
      : _cursor = seed % 7,
        _last = -1;

  int _cursor;
  int _last;

  /// Returns the next entry from [pool], different from the previous
  /// pick whenever the pool holds more than one entry.
  String next(List<String> pool) {
    if (pool.isEmpty) return "";
    if (pool.length == 1) return pool.first;
    int index = (_cursor + _last + 1) % pool.length;
    while (index == _last) {
      index = (index + 1) % pool.length;
    }
    _last = index;
    _cursor = (_cursor + 3) % pool.length;
    return pool[index];
  }
}

/// One-shot pick for call sites that do not keep a picker alive.
String pickVocab(List<String> pool, int seed) {
  if (pool.isEmpty) return "";
  return pool[seed % pool.length];
}

/// One-shot pick that avoids [avoid] when the pool allows it.
String pickVocabAvoiding(List<String> pool, int seed, String avoid) {
  if (pool.isEmpty) return "";
  final String first = pool[seed % pool.length];
  if (pool.length == 1 || first != avoid) return first;
  return pool[(seed + 1) % pool.length];
}
