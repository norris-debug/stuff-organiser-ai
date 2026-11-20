import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech;

import '../models/item.dart';
import '../models/space.dart';
import '../services/coach_vocab_pools.dart';
import '../state/app_state.dart';
import '../state/app_state_spaces.dart';
import '../theme/app_theme.dart';
import '../widgets/mascot_widget.dart';
import 'scan_forward_mailto.dart';
import 'web_camera.dart';
import 'web_keyboard.dart';

part 'scan_flow_models.dart';
part 'scan_flow_draft.dart';
part 'scan_flow_forward.dart';
part 'scan_flow_capture.dart';
part 'scan_flow_dictation.dart';
part 'scan_flow_analyze.dart';
part 'scan_flow_after.dart';
part 'scan_flow_recognition.dart';
part 'scan_flow_recognition_flow.dart';
part 'scan_flow_chat.dart';
part 'scan_flow_ui1.dart';
part 'scan_flow_ui2.dart';
part 'scan_flow_ui2b.dart';
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
/// v0.8.16: the scan's leave-behinds run the moment the result page
/// opens - the tidy plan auto-saves (closing the tab can no longer lose
/// suggestions), the scanned venue auto-adds to "Your spaces" and the
/// recognized objects land as unpacked items on the venue's page.
/// v0.8.17: the coach vocabulary rotates per scan (seeded no-repeat
/// bundles) and the scan-to-email forward action gives app-user scans a
/// path to the recognition lane on the interim route.
/// v0.8.18 (R2-01): the plan save reads a snapshot handed in by the
/// caller, so a flow reset racing the side effects can no longer turn
/// the save into a silent no-op.
class ScanFlowScreen extends StatefulWidget {
  const ScanFlowScreen({
    super.key,
    required this.prefs,
    required this.mascot,
    required this.pack,
    required this.appState,
  });

  final SharedPreferences prefs;
  final MascotVariant mascot;
  final ThemePack pack;

  /// v0.8.16: the venue auto-add and the recognized-item handoff write
  /// through the shared app state.
  final AppState appState;

  @override
  State<ScanFlowScreen> createState() => _ScanFlowScreenState();
}

enum _ScanStage { pick, chat, result }

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

  /// v0.8.16: the recognized objects of this scan, merged across every
  /// uploaded angle. They land as unpacked items on the venue's page
  /// when the result opens.
  List<_RecognizedObject> _recognized = <_RecognizedObject>[];

  /// v0.8.16: the scan's leave-behinds run exactly once, when the result
  /// page opens.
  bool _scanSideEffectsDone = false;

  /// v0.8.9: coach confirmation replies. The reply bar shows when the
  /// latest revealed line asks the user to confirm or correct something;
  /// the answer lands as a user bubble right after that line.
  final TextEditingController _chatReplyController = TextEditingController();
  final Set<int> _answeredConfirmations = <int>{};

  bool get _showChatReplyBar {
    if (_stage != _ScanStage.chat) return false;
    if (_revealed <= 0 || _revealed > _lines.length) return false;
    final _ChatLine last = _lines[_revealed - 1];
    return last.isConfirmation &&
        !_answeredConfirmations.contains(_revealed - 1);
  }

  /// Sends the user's reply to a coach confirmation. The reply is added
  /// as a user bubble directly after the confirmation line so the chat
  /// keeps its order, then that line stops asking.
  void _submitChatReply() {
    final String text = _chatReplyController.text.trim();
    if (text.isEmpty) return;
    if (!_showChatReplyBar) return;
    final int at = _revealed - 1;
    final List<_ChatLine> lines = <_ChatLine>[..._lines];
    lines.insert(at + 1, _ChatLine(text: text, isUser: true));
    _answeredConfirmations.add(at);
    _setUiState(() {
      _lines = lines;
      _revealed++;
      _chatReplyController.clear();
    });
    _scrollToBottom();
    // v0.8.14: a reply that lands on the final line also finishes the
    // reveal (the old Show-my-tidy-plan button is gone).
    _maybeFinishChatReveal();
  }
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

  /// v0.7: the result-stage back arrow returns to the home shell.
  /// v0.8.16 (TC-23): the plan auto-saves when the result page opens, so
  /// the back arrow can no longer discard suggestions - closing the tab
  /// keeps everything the scan produced.
  void _discardAndHome() {
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  /// v0.8.16 (TC-23): the plan is already saved by the time the result
  /// page shows, so returning home only navigates.
  void _saveThenHome() {
    _discardAndHome();
  }

  /// v0.8.16 (TC-23): same as above - the save happened at result entry,
  /// so starting a fresh round only resets the flow.
  void _saveThenNewRound() {
    _resetFlow();
  }

  /// v0.7: appends the coach's suggestions to the Tidy Plan tab as a new
  /// part named for the picked venue. The storage key must stay in sync
  /// with PlanScreen._dataKey (tidy_plan_todo_v1).
  /// v0.8.18 (R2-01): the plan and venue ride in as parameters so the
  /// caller can hand over a snapshot taken before its awaits - a
  /// _resetFlow() racing the save can no longer turn it into a silent
  /// no-op. Null keeps the old live-state behavior.
  static const String _tidyPlanStorageKey = 'tidy_plan_todo_v1';
  static int _scanIdCounter = 0;

  String _newScanId() {
    _scanIdCounter++;
    return 't${DateTime.now().microsecondsSinceEpoch}-$_scanIdCounter';
  }

  Future<_SaveResult> _savePlanToTidyList({_ScanPlan? plan, String? venue}) async {
    final _ScanPlan savedPlan = plan ?? _plan;
    final String savedVenue = venue ?? _scanVenue;
    if (savedPlan.suggestions.isEmpty) return _SaveResult.empty;
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
      // v0.8.16 (TC-11): a corrupt store is reported, never silently
      // treated as "nothing to save" - and never overwritten with a
      // partial save.
      return _SaveResult.corrupt;
    }
    final String partName = savedVenue.isNotEmpty ? savedVenue : 'Scanned space';
    final List<Map<String, dynamic>> tasks = <Map<String, dynamic>>[];
    for (final _Suggestion suggestion in savedPlan.suggestions) {
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
    return _SaveResult.saved;
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
      _recognized = <_RecognizedObject>[];
      _scanSideEffectsDone = false;
      _chatReplyController.clear();
      _answeredConfirmations.clear();
    });
  }
}
