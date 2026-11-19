import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/mascot_widget.dart';

/// Chat driven room scan for Stuff Organiser AI.
///
/// The flow has three stages: the user picks a photo, the coach chats the
/// organising plan step by step, and the result stage shows a concept preview
/// of the tidied space together with the complete plan notes.
///
/// Live photo analysis uses the Gemini v1beta REST endpoint and needs an API
/// key that is stored in the local preferences. Without a key the built-in
/// demo coach runs completely offline.
class ScanFlowScreen extends StatefulWidget {
  const ScanFlowScreen({
    super.key,
    required this.prefs,
    required this.mascot,
    required this.pack,
  });

  /// Preferences used to persist the optional Gemini API key.
  final SharedPreferences prefs;

  /// Mascot variant used by the coach avatar.
  final MascotVariant mascot;

  /// Theme pack used by the mascot widget.
  final ThemePack pack;

  @override
  State<ScanFlowScreen> createState() => _ScanFlowScreenState();
}

/// Stages of the scan flow.
enum _ScanStage { pick, chat, result }

/// A single bubble inside the coach chat.
class _ChatLine {
  const _ChatLine({
    required this.text,
    this.isUser = false,
    this.isPhoto = false,
  });

  /// Text of the bubble.
  final String text;

  /// Whether the line was said by the user.
  final bool isUser;

  /// Whether the line renders the scanned photo.
  final bool isPhoto;
}

/// Tidy plan produced by the coach.
class _ScanPlan {
  const _ScanPlan({
    required this.observations,
    required this.steps,
    required this.habits,
  });

  /// Things the coach noticed in the room.
  final List<String> observations;

  /// Ordered actions that tidy the room.
  final List<String> steps;

  /// Habits that keep the room tidy.
  final List<String> habits;
}

class _ScanFlowScreenState extends State<ScanFlowScreen> {
  /// Preferences key that stores the optional Gemini API key.
  static const String _prefsKey = 'scan_gemini_api_key';

  /// Gemini v1beta REST endpoint used for live photo analysis.
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Prompt sent with the photo, asking the model for a strict JSON plan.
  static const String _kPrompt =
      'You are Tidy Coach, a friendly anime organising assistant inside the '
      'Stuff Organiser AI app. Look at the room photo that was uploaded and '
      'reply ONLY with minified JSON in exactly this shape: '
      '{"observations":[2-4 short friendly observations],'
      '"steps":[4-6 ordered imperative actions each starting "Step N:"],'
      '"habits":[2-3 tidy habits]}. No markdown, no code fences and no extra '
      'commentary. Keep a warm, encouraging tone and never use emojis.';

  final ImagePicker _picker = ImagePicker();
  final ScrollController _chatScroll = ScrollController();

  Uint8List? _photoBytes;
  String _mimeType = 'image/jpeg';
  bool _analyzing = false;
  bool _usedFallback = false;
  String? _error;
  String? _apiKey;
  List<_ChatLine> _lines = <_ChatLine>[];
  int _revealed = 0;
  _ScanStage _stage = _ScanStage.pick;
  _ScanPlan _plan = const _ScanPlan(
    observations: <String>[],
    steps: <String>[],
    habits: <String>[],
  );

  @override
  void initState() {
    super.initState();
    _apiKey = widget.prefs.getString(_prefsKey);
  }

  @override
  void dispose() {
    _chatScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _ScanStage.pick => _buildPickStage(),
      _ScanStage.chat => _buildChatStage(),
      _ScanStage.result => _buildResultStage(),
    };
  }

  /// Stage one: pick a photo and see whether live analysis is available.
  Widget _buildPickStage() {
    final ThemeData theme = Theme.of(context);
    final bool live = (_apiKey ?? '').isNotEmpty;
    final String? error = _error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan a room'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Gemini API key',
            icon: const Icon(Icons.key_outlined),
            onPressed: _openApiKeyDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    MascotWidget(
                      variant: widget.mascot,
                      pack: widget.pack,
                      size: 120,
                      mood: MascotMood.happy,
                      celebrationTick: 0,
                    ),
                    const SizedBox(height: 12),
                    Text('Scan your room', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Take a photo of the space you want to tidy up. The coach '
                      'will chat you through organising it, then hand you a '
                      'preview and the full plan.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Chip(label: Text(live ? 'Live AI' : 'Demo analysis')),
                    const SizedBox(height: 16),
                    if (_analyzing) ...<Widget>[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        'The coach is studying your photo...',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _analyzing ? null : () => _capture(fromCamera: true),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Open camera'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _analyzing ? null : () => _capture(fromCamera: false),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Choose photo'),
                      ),
                    ),
                    if (error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stage two: the coach chats the plan step by step.
  Widget _buildChatStage() {
    final List<_ChatLine> visible = _lines.take(_revealed).toList();
    final int firstCoachLine =
        visible.indexWhere((_ChatLine line) => !line.isUser && !line.isPhoto);

    return Scaffold(
      appBar: AppBar(title: const Text('Room scan')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _chatScroll,
              padding: const EdgeInsets.all(16),
              itemCount: visible.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildChatBubble(visible[index], index == firstCoachLine);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: _revealed < _lines.length
                    ? FilledButton(
                        onPressed: _revealNext,
                        child: const Text('Next'),
                      )
                    : FilledButton(
                        onPressed: _openResult,
                        child: const Text('Show my tidy plan'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Stage three: concept preview plus the complete plan notes.
  Widget _buildResultStage() {
    final ThemeData theme = Theme.of(context);
    final Uint8List? bytes = _photoBytes;

    return Scaffold(
      appBar: AppBar(title: const Text('Your tidy plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MascotWidget(
                variant: widget.mascot,
                pack: widget.pack,
                size: 64,
                mood: MascotMood.cheer,
                celebrationTick: 0,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('All done!', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Here is the estimated tidied space and your complete plan.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                bytes,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          _buildConceptPreview(),
          const SizedBox(height: 16),
          _buildNotesCard(),
          if (_usedFallback) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Live analysis was unavailable, so the built-in demo coach notes '
              'are shown.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyPlan,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy all'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _resetFlow,
                  child: const Text('Scan another room'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Soft gradient preview of the tidied space.
  Widget _buildConceptPreview() {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('After tidy-up - concept preview', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                ),
              ),
              child: Column(
                children: <Widget>[
                  _buildPreviewRow(Icons.weekend, 'Rest areas cleared'),
                  _buildPreviewRow(Icons.kitchen, 'Kitchen zones reset'),
                  _buildPreviewRow(Icons.inventory_2_outlined, 'Shelves and surfaces organised'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Concept illustration of the end state. A photoreal after-photo '
              'lands with the image-gen add-on.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// One row of the concept preview.
  Widget _buildPreviewRow(IconData icon, String label) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }

  /// Complete plan notes: what the coach saw, the steps and the habits.
  Widget _buildNotesCard() {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Your complete plan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('What the coach saw', style: theme.textTheme.titleSmall),
            ..._buildNoteRows(_plan.observations),
            const SizedBox(height: 12),
            Text('Step-by-step plan', style: theme.textTheme.titleSmall),
            ..._buildNoteRows(_plan.steps),
            const SizedBox(height: 12),
            Text('Keep it tidy', style: theme.textTheme.titleSmall),
            ..._buildNoteRows(_plan.habits),
          ],
        ),
      ),
    );
  }

  /// Bullet style rows used by the notes card.
  List<Widget> _buildNoteRows(List<String> items) {
    return items
        .map(
          (String item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.check_circle_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(item)),
              ],
            ),
          ),
        )
        .toList();
  }

  /// Renders one chat bubble.
  Widget _buildChatBubble(_ChatLine line, bool showAvatar) {
    final ThemeData theme = Theme.of(context);
    final Uint8List? bytes = _photoBytes;

    if (line.isPhoto) {
      if (bytes == null) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(bytes, width: 220, fit: BoxFit.cover),
          ),
        ),
      );
    }

    if (line.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(line.text),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: MascotWidget(
                variant: widget.mascot,
                pack: widget.pack,
                size: 36,
                celebrationTick: 0,
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(line.text),
            ),
          ),
        ],
      ),
    );
  }

  /// Picks a photo and runs the coach analysis.
  Future<void> _capture({required bool fromCamera}) async {
    setState(() {
      _analyzing = true;
      _error = null;
    });

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1280,
      );
    } catch (_) {
      picked = null;
    }
    if (!mounted) return;
    if (picked == null) {
      setState(() => _analyzing = false);
      return;
    }
    final XFile file = picked;

    Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _error = 'That photo could not be read. Try another picture.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
      _mimeType = file.mimeType ?? 'image/jpeg';
    });

    _ScanPlan plan;
    bool usedFallback = false;
    if ((_apiKey ?? '').isNotEmpty) {
      try {
        plan = await _analyzeWithGemini();
      } catch (_) {
        plan = _demoPlan();
        usedFallback = true;
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      plan = _demoPlan();
    }
    if (!mounted) return;

    final List<_ChatLine> lines = <_ChatLine>[
      const _ChatLine(text: 'Your photo', isPhoto: true),
      ..._buildChatLines(plan),
    ];
    setState(() {
      _plan = plan;
      _lines = lines;
      _revealed = 1;
      _stage = _ScanStage.chat;
      _analyzing = false;
      _usedFallback = usedFallback;
    });
    _scrollToBottom();
  }

  /// Builds the coach dialogue for a plan.
  List<_ChatLine> _buildChatLines(_ScanPlan plan) {
    final List<_ChatLine> lines = <_ChatLine>[];

    lines.add(
      const _ChatLine(
        text: 'Nice shot - I have studied your room. Here is what stands out.',
      ),
    );
    for (final String observation in plan.observations) {
      lines.add(_ChatLine(text: observation));
    }
    lines.add(
      const _ChatLine(text: 'Makes sense - what do I do first?', isUser: true),
    );
    lines.add(
      const _ChatLine(
        text: 'Here is your step-by-step plan - take them in order.',
      ),
    );
    for (final String step in plan.steps) {
      lines.add(_ChatLine(text: step));
    }
    lines.add(const _ChatLine(text: 'Got it.', isUser: true));
    lines.add(
      const _ChatLine(text: 'Two small habits will keep it looking like this:'),
    );
    for (final String habit in plan.habits) {
      lines.add(_ChatLine(text: habit));
    }
    lines.add(
      const _ChatLine(
        text: 'That is the whole plan! Tap Show my tidy plan for the preview '
            'and your notes.',
      ),
    );

    return lines;
  }

  /// Offline coach plan used when no API key is set or when the live call fails.
  _ScanPlan _demoPlan() {
    return const _ScanPlan(
      observations: <String>[
        'The floor is doing a lot of the storage right now - that is the first '
            'thing to fix.',
        'Surfaces have turned into landing zones for things that already have '
            'homes.',
      ],
      steps: <String>[
        'Step 1: Clear the floor first so you can see what you are working with.',
        'Step 2: Group like items into keep, relocate, bin and donate piles.',
        'Step 3: Give every group a home so nothing ends up back on the floor.',
        'Step 4: Put things back zone by zone, starting with the busiest surface.',
        'Step 5: Run a 10-minute timer sprint to finish the last corners.',
      ],
      habits: <String>[
        'Reset each surface to empty before bed.',
        'One in, one out: new item arrives, something leaves.',
      ],
    );
  }

  /// Sends the photo to Gemini and turns the answer into a plan.
  Future<_ScanPlan> _analyzeWithGemini() async {
    final String apiKey = _apiKey ?? '';
    final Uint8List bytes = _photoBytes ?? Uint8List(0);
    if (apiKey.isEmpty || bytes.isEmpty) {
      throw StateError('Live analysis needs an API key and a photo.');
    }

    final Map<String, dynamic> request = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{
              'inline_data': <String, String>{
                'mime_type': _mimeType,
                'data': base64Encode(bytes),
              },
            },
            <String, String>{'text': _kPrompt},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'temperature': 0.4,
        'responseMimeType': 'application/json',
      },
    };

    final http.Response response = await http
        .post(
          Uri.parse(_geminiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode(request),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw StateError('Gemini request failed with status ${response.statusCode}.');
    }

    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Unexpected Gemini response shape.');
    }
    final Object? candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw StateError('Gemini returned no candidates.');
    }
    final Object? candidate = candidates.first;
    if (candidate is! Map<String, dynamic>) {
      throw StateError('Unexpected Gemini candidate shape.');
    }
    final Object? content = candidate['content'];
    if (content is! Map<String, dynamic>) {
      throw StateError('Unexpected Gemini content shape.');
    }

    final StringBuffer buffer = StringBuffer();
    final Object? parts = content['parts'];
    if (parts is List) {
      for (final Object? part in parts) {
        if (part is Map<String, dynamic>) {
          final Object? text = part['text'];
          if (text is String) {
            buffer.write(text);
          }
        }
      }
    }

    final String raw = buffer.toString().trim();
    final int start = raw.indexOf('{');
    final int end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw StateError('Gemini did not return a JSON plan.');
    }
    final Object? parsed = jsonDecode(raw.substring(start, end + 1));
    if (parsed is! Map<String, dynamic>) {
      throw StateError('Unexpected Gemini plan shape.');
    }

    final List<String> observations = _stringList(parsed['observations']);
    final List<String> steps = _stringList(parsed['steps']);
    final List<String> habits = _stringList(parsed['habits']);
    final _ScanPlan demo = _demoPlan();

    return _ScanPlan(
      observations: observations.isEmpty ? demo.observations : observations,
      steps: steps.isEmpty ? demo.steps : steps,
      habits: habits.isEmpty ? demo.habits : habits,
    );
  }

  /// Reads a JSON array of strings, dropping blank entries.
  List<String> _stringList(Object? value) {
    if (value is! List) {
      return <String>[];
    }
    final List<String> result = <String>[];
    for (final Object? entry in value) {
      if (entry is String) {
        final String trimmed = entry.trim();
        if (trimmed.isNotEmpty) {
          result.add(trimmed);
        }
      }
    }
    return result;
  }

  /// Reveals the next chat line.
  void _revealNext() {
    setState(() {
      if (_revealed < _lines.length) {
        _revealed += 1;
      }
    });
    _scrollToBottom();
  }

  /// Opens the result stage.
  void _openResult() {
    setState(() => _stage = _ScanStage.result);
  }

  /// Scrolls the chat to the newest line.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScroll.hasClients) return;
      _chatScroll.animateTo(
        _chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Copies the complete plan as plain text.
  Future<void> _copyPlan() async {
    await Clipboard.setData(ClipboardData(text: _planDigest()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan copied')),
    );
  }

  /// Builds the plain text digest of the plan.
  String _planDigest() {
    final StringBuffer buffer = StringBuffer()
      ..writeln('Stuff Organiser AI - tidy plan')
      ..writeln()
      ..writeln('What the coach saw');
    for (final String item in _plan.observations) {
      buffer.writeln('- $item');
    }
    buffer
      ..writeln()
      ..writeln('Step-by-step plan');
    for (final String item in _plan.steps) {
      buffer.writeln('- $item');
    }
    buffer
      ..writeln()
      ..writeln('Keep it tidy');
    for (final String item in _plan.habits) {
      buffer.writeln('- $item');
    }
    return buffer.toString();
  }

  /// Resets the flow back to the photo picker.
  void _resetFlow() {
    setState(() {
      _stage = _ScanStage.pick;
      _photoBytes = null;
      _mimeType = 'image/jpeg';
      _lines = <_ChatLine>[];
      _revealed = 0;
      _analyzing = false;
      _usedFallback = false;
      _error = null;
      _plan = const _ScanPlan(
        observations: <String>[],
        steps: <String>[],
        habits: <String>[],
      );
    });
  }

  /// Opens the dialog that sets or clears the Gemini API key.
  Future<void> _openApiKeyDialog() async {
    final TextEditingController controller =
        TextEditingController(text: _apiKey ?? '');

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Gemini API key'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Paste your Gemini API key',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('clear'),
              child: const Text('Clear key'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final String typed = controller.text.trim();
    controller.dispose();
    if (result == null) return;

    if (result == 'clear') {
      await widget.prefs.remove(_prefsKey);
      if (!mounted) return;
      setState(() => _apiKey = null);
      return;
    }

    await widget.prefs.setString(_prefsKey, typed);
    if (!mounted) return;
    setState(() => _apiKey = typed);
  }
}
