import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech;

import '../theme/app_theme.dart';
import '../widgets/mascot_widget.dart';
import 'web_camera.dart';
import 'web_keyboard.dart';

part 'scan_flow_capture.dart';
part 'scan_flow_dictation.dart';
part 'scan_flow_analyze.dart';
part 'scan_flow_after.dart';
part 'scan_flow_recognition.dart';
part 'scan_flow_recognition_flow.dart';
part 'scan_flow_chat.dart';
part 'scan_flow_ui1.dart';
part 'scan_flow_ui2.dart';
part 'scan_flow_ui3.dart';
part 'scan_flow_thinking.dart';
part 'scan_flow_loader.dart';

/// Scan feature (v0.7.0).
///
/// The coach looks at the photos that were actually taken and proposes a
/// number of concrete physical actions that scales with the messiness.
/// v0.7 adds the venue chooser: the picked room rides with the request so
/// the Cellulose lane reads the space with context, and it names the part
/// that is auto-saved into the Tidy Plan tab. Interpretation stays on the
/// Cellulose lane (v0.6.9), the Next control remains rate limited, and the
/// result stage now carries the thinking state.
/// v0.8.5: the coach drafts from the recognition lane's object list
/// instead of the canned demo script, so the dialogue follows the
/// photos that were actually taken.
class ScanFlowScreen extends StatefulWidget {
  const ScanFlowScreen({
    super.key,
    required this.prefs,
    required this.mascot,
    required this.pack,
  });

  final SharedPreferences prefs;
  final MascotVariant mascot;
  final ThemePack pack;

  @override
  State<ScanFlowScreen> createState() => _ScanFlowScreenState();
}

enum _ScanStage { pick, chat, result }

class _ChatLine {
  const _ChatLine({
    required this.text,
    this.isUser = false,
    this.isPhoto = false,
    this.isHeading = false,
  });

  final String text;
  final bool isUser;
  final bool isPhoto;
  final bool isHeading;
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

/// The full result of one scan.
class _ScanPlan {
  const _ScanPlan({
    required this.observations,
    required this.habits,
    this.suggestions = const <_Suggestion>[],
    this.setting = '',
    this.tidiness = '',
  });

  /// The venue picked for this scan round (empty when the user skipped it).
  final String setting;

  /// tidy | moderate | messy (empty when it could not be detected).
  final String tidiness;

  final List<String> observations;
  final List<_Suggestion> suggestions;
  final List<String> habits;

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

/// Interjections the coach drops between suggestions.
const List<String> _interjections = <String>[
  'Makes sense.',
  'That one I can do right now.',
  'Good tip.',
  'Noted, next one.',
  'Okay, next.',
];

class _ScanFlowScreenState extends State<ScanFlowScreen> {
  final ImagePicker _picker = ImagePicker();
  final ScrollController _chatScroll = ScrollController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  speech.SpeechToText? _speech;
  String _dictationBase = '';
  bool _speechAvailable = false;
  bool _listening = false;

  List<_PhotoItem> _photos = <_PhotoItem>[];
  bool _analyzing = false;

  /// v0.8.5: true while the coach chat waits for the recognized list.
  bool _awaitingRecognition = false;
  String? _error;
  List<_ChatLine> _lines = <_ChatLine>[];
  int _revealed = 0;
  int _runId = 0;
  _ScanStage _stage = _ScanStage.pick;
  _ScanPlan _plan = const _ScanPlan(
    observations: <String>[],
    habits: <String>[],
  );

  /// Timestamp of the last accepted Next press (rate limiting).
  DateTime _lastNextAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _chatScroll.dispose();
    _notesController.dispose();
    _venueController.dispose();
    _speech?.stop();
    // v0.8.6: the scan flow is the only screen that opens the web camera
    // sheet, so it owns the full release of the shared camera session.
    releaseWebCamera();
    super.dispose();
  }

  /// Rebuild wrapper for the part-file extensions: they sit outside the
  /// State subclass, where calling setState directly is a protected-member
  /// violation.
  void _setUiState(VoidCallback fn) {
    setState(fn);
  }

  /// The picked venue for this scan round (empty when the user skipped it).
  String get _scanVenue => _venueController.text.trim();

  String get _stageTitle => switch (_stage) {
        _ScanStage.pick => 'Scan your space',
        _ScanStage.chat => 'Coach chat',
        _ScanStage.result => 'Your tidy plan',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stageTitle),
        leading: _stage == _ScanStage.result
            ? BackButton(onPressed: _discardAndHome)
            : null,
        actions: _stage == _ScanStage.result
            ? <Widget>[
                IconButton(
                  tooltip: 'Copy plan text',
                  icon: const Icon(Icons.copy_all_outlined),
                  onPressed: _copyPlan,
                ),
              ]
            : null,
      ),
      body: switch (_stage) {
        _ScanStage.pick => _buildPick(context),
        _ScanStage.chat => _buildChat(context),
        _ScanStage.result => _buildResult(context),
      },
    );
  }

  /// v0.7: the result-stage back arrow discards the suggestions without
  /// saving and returns to the home shell.
  void _discardAndHome() {
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  /// v0.7: 'Return to homepage' saves the suggestions into the Tidy Plan
  /// tab first, then pops back to the home shell.
  Future<void> _saveThenHome() async {
    await _savePlanToTidyList();
    if (!mounted) return;
    _discardAndHome();
  }

  /// v0.7: 'Scan another room' saves first, then starts a fresh round.
  Future<void> _saveThenNewRound() async {
    final bool saved = await _savePlanToTidyList();
    if (!mounted) return;
    _resetFlow();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Saved to the Tidy Plan tab'
              : 'Nothing to save - new round started',
        ),
      ),
    );
  }

  /// v0.7: appends the coach's suggestions to the Tidy Plan tab as a new
  /// part named for the picked venue. The storage key must stay in sync
  /// with PlanScreen._dataKey (tidy_plan_todo_v1).
  static const String _tidyPlanStorageKey = 'tidy_plan_todo_v1';
  static int _scanIdCounter = 0;

  String _newScanId() {
    _scanIdCounter++;
    return 't${DateTime.now().microsecondsSinceEpoch}-$_scanIdCounter';
  }

  Future<bool> _savePlanToTidyList() async {
    if (_plan.suggestions.isEmpty) return false;
    final SharedPreferences prefs = widget.prefs;
    final String raw = prefs.getString(_tidyPlanStorageKey) ?? '';
    List<dynamic> parts;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List<dynamic>) {
        parts = decoded;
      } else {
        parts = <dynamic>[];
      }
    } catch (_) {
      // Corrupt store: never overwrite existing data with a partial save.
      return false;
    }
    final String venue = _scanVenue;
    final String partName = venue.isNotEmpty ? venue : 'Scanned space';
    final List<Map<String, dynamic>> tasks = <Map<String, dynamic>>[];
    for (final _Suggestion suggestion in _plan.suggestions) {
      final String steps = suggestion.steps.join(' -> ');
      String detail = suggestion.detail;
      if (steps.isNotEmpty) {
        detail = detail.isEmpty
            ? 'How to do it: $steps'
            : '$detail How to do it: $steps';
      }
      tasks.add(<String, dynamic>{
        'id': _newScanId(),
        'text': suggestion.title,
        'details': detail,
        'done': false,
      });
    }
    parts.add(<String, dynamic>{
      'id': _newScanId(),
      'name': partName,
      'tasks': tasks,
    });
    await prefs.setString(_tidyPlanStorageKey, jsonEncode(parts));
    return true;
  }

  void _resetFlow() {
    _runId++;
    unawaited(_stopListening());
    _setUiState(() {
      _photos = <_PhotoItem>[];
      _notesController.clear();
      _venueController.clear();
      _listening = false;
      _lines = <_ChatLine>[];
      _revealed = 0;
      _stage = _ScanStage.pick;
      _plan = const _ScanPlan(
        observations: <String>[],
        habits: <String>[],
      );
      _error = null;
      _analyzing = false;
      _awaitingRecognition = false;
    });
  }
}
