import 'dart:async';

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

part 'scan_flow_capture.dart';
part 'scan_flow_dictation.dart';
part 'scan_flow_analyze.dart';
part 'scan_flow_after.dart';
part 'scan_flow_demo.dart';
part 'scan_flow_demo_banks.dart';
part 'scan_flow_chat.dart';
part 'scan_flow_ui1.dart';
part 'scan_flow_ui2.dart';
part 'scan_flow_ui3.dart';
part 'scan_flow_thinking.dart';

/// Scan feature (v0.6.9).
///
/// The coach looks at the photos that were actually taken and proposes a
/// number of concrete physical actions that scales with the messiness.
/// v0.6.9 routes interpretation and layout to the Cellulose lane: the
/// in-app Gemini key flow is fully removed and the thinking state covers
/// the wait while results come back. The Next control is rate limited so
/// rapid tapping cannot outrun the coach, and title texts use a larger
/// display font.
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
  });

  /// Comma separated list of the surfaces and areas visible in the photo.
  final String setting = '';

  /// tidy | moderate | messy (empty when it could not be detected).
  final String tidiness = '';

  final List<String> observations;
  final List<_Suggestion> suggestions;
  final List<String> habits;

  bool get hasSetting => setting.trim().isNotEmpty;
  bool get hasTidiness => tidiness.trim().isNotEmpty;
}

/// Offline play book used by the demo coach.
class _DemoBank {
  const _DemoBank({
    required this.observations,
    required this.suggestions,
    required this.habits,
  });

  final List<String> observations;
  final List<_Suggestion> suggestions;
  final List<String> habits;
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
  speech.SpeechToText? _speech;
  String _dictationBase = '';
  bool _speechAvailable = false;
  bool _listening = false;

  List<_PhotoItem> _photos = <_PhotoItem>[];
  bool _analyzing = false;
  String? _error;
  List<_ChatLine> _lines = <_ChatLine>[];
  int _revealed = 0;
  int _runId = 0;
  _ScanStage _stage = _ScanStage.pick;
  _ScanPlan _plan = const _ScanPlan(
    observations: <String>[],
    habits: <String>[],
  );

  Uint8List? _afterBytes;
  String? _afterUrl;
  bool _afterLoading = false;

  /// Timestamp of the last accepted Next press (rate limiting).
  DateTime _lastNextAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _chatScroll.dispose();
    _notesController.dispose();
    _speech?.stop();
    super.dispose();
  }

  /// Rebuild wrapper for the part-file extensions: they sit outside the
  /// State subclass, where calling setState directly is a protected-member
  /// violation.
  void _setUiState(VoidCallback fn) {
    setState(fn);
  }

  String get _stageTitle => switch (_stage) {
        _ScanStage.pick => 'Scan your space',
        _ScanStage.chat => 'Coach chat',
        _ScanStage.result => 'Your tidy plan',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_stageTitle)),
      body: switch (_stage) {
        _ScanStage.pick => _buildPick(context),
        _ScanStage.chat => _buildChat(context),
        _ScanStage.result => _buildResult(context),
      },
    );
  }
}
