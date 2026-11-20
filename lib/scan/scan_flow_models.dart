part of 'scan_flow.dart';

// v0.8.17: the scan flow's shared model types live in their own part
// file so every scan library file stays push- and verify-sized (the
// v0.8.11 split convention). The members moved here are part of the
// same library, so no other file changes.

class _ChatLine {
  const _ChatLine({
    required this.text,
    this.isUser = false,
    this.isPhoto = false,
    this.isHeading = false,
    this.isConfirmation = false,
    this.isPasteAction = false,
  });

  final String text;
  final bool isUser;
  final bool isPhoto;
  final bool isHeading;

  /// v0.8.9: the coach asks the user to confirm or correct something on
  /// this line, so the chat shows a reply bar while it is the latest
  /// revealed line and still unanswered.
  final bool isConfirmation;

  /// v0.8.11: this line carries the quiet inline paste link (the
  /// recognition lane's interim manual route) so the waiting bubble
  /// never leaves the scan without a way in.
  final bool isPasteAction;
}

/// One concrete, physical action the coach proposes.
class _Suggestion {
  const _Suggestion({
    required this.title,
    required this.detail,
    required this.steps,
  });

  final String title;
  final String detail;
  final List<String> steps;
}

/// v0.8.16 (TC-11): outcomes of saving the tidy plan, so the messaging
/// can tell "nothing to save" apart from "the stored plan data is
/// unreadable".
enum _SaveResult { saved, empty, corrupt }

/// The full result of one scan.
class _ScanPlan {
  const _ScanPlan({
    required this.observations,
    required this.habits,
    this.suggestions = const <_Suggestion>[],
    this.setting = '',
    this.tidiness = '',
    this.observationConfirmations = const <bool>[],
  });

  /// The venue picked for this scan round (empty when the user skipped it).
  final String setting;

  /// tidy | moderate | messy (empty when it could not be detected).
  final String tidiness;

  final List<String> observations;
  final List<_Suggestion> suggestions;
  final List<String> habits;

  /// v0.8.17: parallel to [observations] - true where the observation is
  /// a coach confirmation point (verify / flagged tier reads), so the
  /// chat no longer detects them by matching fixed opening words.
  final List<bool> observationConfirmations;

  bool get hasSetting => setting.trim().isNotEmpty;
  bool get hasTidiness => tidiness.trim().isNotEmpty;

  /// Returns this plan with the picked venue folded into the setting, so
  /// the venue rides through the chat intro, the chips and the digest.
  _ScanPlan withVenue(String venue) {
    if (venue.trim().isEmpty) return this;
    return _ScanPlan(
      setting: venue.trim(),
      tidiness: tidiness,
      observations: observations,
      habits: habits,
      suggestions: suggestions,
      observationConfirmations: observationConfirmations,
    );
  }
}

/// One photo in the scan: the main shot plus up to five extra angles.
class _PhotoItem {
  const _PhotoItem({required this.bytes, required this.mime});

  final Uint8List bytes;
  final String mime;
}

/// Maximum photos per scan: the main shot plus five extra angles.
const int _maxPhotos = 6;

/// v0.8.17: the per-scan vocabulary bundle - one no-repeat picker per
/// wording role, all seeded from one scan seed so one conversation stays
/// coherent while different scans read differently.
class _CoachVocab {
  _CoachVocab(this.seed)
      : openers = VocabPicker(seed: seed),
        asides = VocabPicker(seed: seed + 1),
        leads = VocabPicker(seed: seed + 2),
        verbs = VocabPicker(seed: seed + 3),
        asks = VocabPicker(seed: seed + 5),
        gates = VocabPicker(seed: seed + 6);

  /// The scan seed this bundle was built from.
  final int seed;

  final VocabPicker openers;
  final VocabPicker asides;
  final VocabPicker leads;
  final VocabPicker verbs;
  final VocabPicker asks;
  final VocabPicker gates;
}

/// v0.8.17: the active scan's vocabulary bundle. Re-seeded at the start
/// of every scan (scan_flow_analyze.dart) so each conversation rotates
/// its own wording without repeating consecutive phrases.
_CoachVocab _scanVocab = _CoachVocab(3);
