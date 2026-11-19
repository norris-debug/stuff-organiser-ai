import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/mascot_widget.dart';

/// Scan feature (v0.5).
///
/// The coach looks at the photo that was actually taken, names the visible
/// setting and how messy it really is, and proposes a number of concrete
/// physical actions that scales with the messiness. With a Gemini key an
/// "after tidying" picture is generated from the same photo, otherwise a
/// keyless concept image is used so the flow never breaks.
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
    this.setting = '',
    this.tidiness = '',
    this.suggestions = const <_Suggestion>[],
  });

  /// Comma separated list of the surfaces and areas visible in the photo.
  final String setting;

  /// tidy | moderate | messy (empty when it could not be detected).
  final String tidiness;

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

class _ScanFlowScreenState extends State<ScanFlowScreen> {
  static const String _prefsKey = 'scan_gemini_api_key';
  static const String _clearSentinel = '__clear__';
  static const String _geminiBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Analysis models, tried in order until one answers.
  static const List<String> _analysisModels = <String>[
    'gemini-2.5-flash',
    'gemini-2.0-flash',
  ];

  /// Image models for the "after tidying" picture, tried in order.
  static const List<String> _imageModels = <String>[
    'gemini-2.5-flash-image',
    'gemini-2.5-flash-image-preview',
    'gemini-2.0-flash-exp',
  ];

  static const List<String> _interjections = <String>[
    'Makes sense.',
    'That one I can do right now.',
    'Good tip.',
    'Noted, next one.',
    'Okay, next.',
  ];

  static const String _kPrompt = '''
You are Tidy Coach, a friendly anime organising assistant inside the Stuff Organiser AI app.
You receive ONE photo of a real space. Analyse what is ACTUALLY visible in that photo and nothing else.

Rules:
1. Look only at the objects, surfaces and areas that are really in the photo. Never reuse a template or generic advice such as declutter your space, organise your belongings, make a plan, or keep it clean.
2. Every suggestion must be a concrete physical action that names the real things you can see and says what to do with them: group, stack, fold, contain, label, relocate, wipe, sort, coil or bin.
3. Work like a professional small space organiser from Hong Kong. First declutter by sorting everything into three piles - keep, relocate, and donate or bin. Then group like with like. Then contain each group in a basket or box and label it. Then use vertical space and frequency based zoning, so daily items sit at hand height and occasional items sit higher up. Finish with a clear floor and clear flat surfaces.
4. Give a tidiness verdict that is exactly one of: tidy, moderate, messy.
5. The number of suggestions must follow the real messiness and must never be a fixed number. tidy means 1 to 2 suggestions, moderate means 4 to 6 suggestions, messy means 8 to 12 suggestions.
6. Setting must be a comma separated list of the surfaces and areas visible in the photo, for example: table, floor, shelf, bed, desk, kitchen counter, wardrobe, sofa, worktop.
7. Steps are short ordered physical instructions that use concrete verbs such as group, stack, fold, contain, label, relocate.

Reply ONLY with minified JSON in exactly this shape:
{"setting":"table, floor","tidiness":"messy","observations":["2 to 4 short friendly observations"],"suggestions":[{"title":"short action title","detail":"one or two sentences about this exact group of items","steps":["step one","step two","step three"]}],"habits":["2 to 3 tidy habits"]}

No markdown, no code fences and no extra commentary. Keep a warm, encouraging tone and never use emojis.
''';

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
  int _runId = 0;
  _ScanStage _stage = _ScanStage.pick;
  _ScanPlan _plan = const _ScanPlan(
    observations: <String>[],
    habits: <String>[],
  );

  Uint8List? _afterBytes;
  String? _afterUrl;
  bool _afterReal = false;
  bool _afterLoading = false;

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

  String get _stageTitle => switch (_stage) {
        _ScanStage.pick => 'Scan your space',
        _ScanStage.chat => 'Coach chat',
        _ScanStage.result => 'Your tidy plan',
      };

  // ---------------------------------------------------------------------
  // Pick stage
  // ---------------------------------------------------------------------

  Future<void> _capture(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _mimeType = _mimeFor(file.path);
      });
      await _analyze();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not open the camera or the gallery. Please try again.';
      });
    }
  }

  String _mimeFor(String path) {
    final String lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  // ---------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------

  Future<void> _analyze() async {
    final Uint8List? bytes = _photoBytes;
    if (bytes == null) return;
    final int runId = ++_runId;
    final String? key = _apiKey;

    setState(() {
      _analyzing = true;
      _error = null;
      _usedFallback = false;
      _lines = <_ChatLine>[];
      _revealed = 0;
      _afterBytes = null;
      _afterUrl = null;
      _afterReal = false;
      _afterLoading = true;
    });

    _ScanPlan plan = _demoPlan(bytes);
    bool fallback = true;
    if (key != null && key.isNotEmpty) {
      try {
        plan = await _analyzeWithGemini(key, bytes, _mimeType);
        fallback = false;
      } on TimeoutException {
        if (mounted) {
          setState(() {
            _error = 'Live analysis timed out, so the offline coach took over.';
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _error = 'Live analysis failed, so the offline coach took over.';
          });
        }
      }
    }

    if (!mounted || runId != _runId) return;
    setState(() {
      _plan = plan;
      _usedFallback = fallback;
      _analyzing = false;
    });
    _buildChatLines();
    unawaited(_generateAfterPhoto(plan, runId));
  }

  Future<_ScanPlan> _analyzeWithGemini(
    String key,
    Uint8List bytes,
    String mime,
  ) async {
    for (final String model in _analysisModels) {
      try {
        final http.Response response = await http
            .post(
              Uri.parse(
                '$_geminiBase/$model:generateContent?key=${Uri.encodeComponent(key)}',
              ),
              headers: const <String, String>{
                'Content-Type': 'application/json',
              },
              body: jsonEncode(<String, Object?>{
                'contents': <Object?>[
                  <String, Object?>{
                    'parts': <Object?>[
                      <String, Object?>{'text': _kPrompt},
                      <String, Object?>{
                        'inlineData': <String, Object?>{
                          'mimeType': mime,
                          'data': base64Encode(bytes),
                        },
                      },
                    ],
                  },
                ],
                'generationConfig': <String, Object?>{
                  'responseMimeType': 'application/json',
                },
              }),
            )
            .timeout(const Duration(seconds: 45));
        if (response.statusCode != 200) continue;
        final _ScanPlan plan = _parsePlanFromText(_responseText(response.body));
        if (plan.suggestions.isNotEmpty || plan.observations.isNotEmpty) {
          return plan;
        }
      } on TimeoutException {
        continue;
      } catch (_) {
        continue;
      }
    }
    throw StateError('Live analysis failed for every model.');
  }

  String _responseText(String body) {
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map) return '';
    final Object? candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';
    final Object? first = candidates.first;
    if (first is! Map) return '';
    final Object? content = first['content'];
    if (content is! Map) return '';
    final Object? parts = content['parts'];
    if (parts is! List) return '';
    final StringBuffer buffer = StringBuffer();
    for (final Object? part in parts) {
      if (part is! Map) continue;
      final Object? text = part['text'];
      if (text != null) buffer.write(text.toString());
    }
    return buffer.toString();
  }

  _ScanPlan _parsePlanFromText(String text) {
    const _ScanPlan empty = _ScanPlan(
      observations: <String>[],
      habits: <String>[],
    );
    final int start = text.indexOf('{');
    final int end = text.lastIndexOf('}');
    if (start == -1 || end <= start) return empty;
    try {
      final Object? decoded = jsonDecode(text.substring(start, end + 1));
      if (decoded is Map) {
        return _parsePlan(Map<String, Object?>.from(decoded));
      }
    } catch (_) {
      return empty;
    }
    return empty;
  }

  _ScanPlan _parsePlan(Map<String, Object?> json) {
    final String setting = json['setting']?.toString().trim() ?? '';
    final String tidiness = _normalizeTidiness(
      json['tidiness']?.toString() ?? '',
    );
    final List<String> observations = _stringList(json['observations']);
    final List<String> habits = _stringList(json['habits']);
    final List<_Suggestion> suggestions = <_Suggestion>[];

    final Object? rawSuggestions = json['suggestions'];
    if (rawSuggestions is List) {
      for (final Object? item in rawSuggestions) {
        if (item is! Map) continue;
        final Map<String, Object?> map = Map<String, Object?>.from(item);
        final String title = map['title']?.toString().trim() ?? '';
        final String detail = map['detail']?.toString().trim() ?? '';
        final List<String> steps = _stringList(map['steps']);
        if (title.isEmpty && detail.isEmpty && steps.isEmpty) continue;
        suggestions.add(
          _Suggestion(
            title: title.isEmpty ? 'Tidy this area' : title,
            detail: detail,
            steps: steps,
          ),
        );
      }
    }

    // Legacy shape: a flat top level steps array is wrapped into suggestions.
    if (suggestions.isEmpty) {
      final List<String> legacy = _stringList(json['steps']);
      int index = 1;
      for (final String step in legacy) {
        suggestions.add(
          _Suggestion(
            title: 'Tidy action $index',
            detail: step,
            steps: <String>[step],
          ),
        );
        index++;
      }
    }

    return _ScanPlan(
      setting: setting,
      tidiness: tidiness,
      observations: observations,
      suggestions: _clampToTidiness(suggestions, tidiness),
      habits: habits,
    );
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return <String>[];
    final List<String> out = <String>[];
    for (final Object? item in value) {
      if (item == null) continue;
      final String text = item.toString().trim();
      if (text.isNotEmpty) out.add(text);
    }
    return out;
  }

  String _normalizeTidiness(String raw) {
    final String value = raw.trim().toLowerCase();
    if (value.isEmpty) return '';
    if (value.contains('mess') ||
        value.contains('clutter') ||
        value.contains('chaos') ||
        value.startsWith('un')) {
      return 'messy';
    }
    if (value.contains('tidy')) return 'tidy';
    if (value.contains('moderate') ||
        value.contains('average') ||
        value.contains('mixed') ||
        value.contains('somewhat') ||
        value.contains('slight')) {
      return 'moderate';
    }
    return value;
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  /// Keeps the suggestion count honest: tidy spaces get at most 2 actions,
  /// moderate at most 6, messy at most 12. Nothing is ever padded or fixed.
  List<_Suggestion> _clampToTidiness(
    List<_Suggestion> items,
    String tidiness,
  ) {
    final int max = switch (tidiness) {
      'tidy' => 2,
      'moderate' => 6,
      'messy' => 12,
      _ => 12,
    };
    if (items.length <= max) return items;
    return items.take(max).toList();
  }

  // ---------------------------------------------------------------------
  // After tidying picture
  // ---------------------------------------------------------------------

  Future<void> _generateAfterPhoto(_ScanPlan plan, int runId) async {
    final String? key = _apiKey;
    final Uint8List? bytes = _photoBytes;
    if (bytes != null && key != null && key.isNotEmpty) {
      try {
        final Uint8List image = await _generateAfterImage(
          key,
          bytes,
          _mimeType,
          plan,
        );
        if (!mounted || runId != _runId) return;
        setState(() {
          _afterBytes = image;
          _afterUrl = null;
          _afterReal = true;
          _afterLoading = false;
        });
        return;
      } catch (_) {
        // Fall through to the keyless concept image.
      }
    }
    final String url = _pollinationsUrl(plan, bytes);
    if (!mounted || runId != _runId) return;
    setState(() {
      _afterBytes = null;
      _afterUrl = url;
      _afterReal = false;
      _afterLoading = false;
    });
  }

  Future<Uint8List> _generateAfterImage(
    String key,
    Uint8List bytes,
    String mime,
    _ScanPlan plan,
  ) async {
    for (final String model in _imageModels) {
      try {
        final Map<String, Object?> body = <String, Object?>{
          'contents': <Object?>[
            <String, Object?>{
              'parts': <Object?>[
                <String, Object?>{'text': _afterInstruction(plan)},
                <String, Object?>{
                  'inlineData': <String, Object?>{
                    'mimeType': mime,
                    'data': base64Encode(bytes),
                  },
                },
              ],
            },
          ],
        };
        if (model == 'gemini-2.0-flash-exp') {
          body['generationConfig'] = <String, Object?>{
            'responseModalities': <String>['TEXT', 'IMAGE'],
          };
        }
        final http.Response response = await http
            .post(
              Uri.parse(
                '$_geminiBase/$model:generateContent?key=${Uri.encodeComponent(key)}',
              ),
              headers: const <String, String>{
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 90));
        if (response.statusCode != 200) continue;
        final Uint8List? image = _extractImageBytes(response.body);
        if (image != null && image.isNotEmpty) return image;
      } on TimeoutException {
        continue;
      } catch (_) {
        continue;
      }
    }
    throw StateError('No image model returned a picture.');
  }

  Uint8List? _extractImageBytes(String body) {
    final Object? decoded = jsonDecode(body);
    if (decoded is! Map) return null;
    final Object? candidates = decoded['candidates'];
    if (candidates is! List) return null;
    for (final Object? candidate in candidates) {
      if (candidate is! Map) continue;
      final Object? content = candidate['content'];
      if (content is! Map) continue;
      final Object? parts = content['parts'];
      if (parts is! List) continue;
      for (final Object? part in parts) {
        if (part is! Map) continue;
        final Object? inline = part['inlineData'] ?? part['inline_data'];
        if (inline is! Map) continue;
        final Object? data = inline['data'];
        if (data is! String || data.isEmpty) continue;
        try {
          return base64Decode(data);
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  String _afterInstruction(_ScanPlan plan) {
    final String where =
        plan.hasSetting ? 'the same ${plan.setting}' : 'the same room';
    return 'Edit this photo so it shows $where after tidying. Keep the exact '
        'same camera angle, the same furniture, the same room shape and the '
        'same lighting. Show everything tidied: flat surfaces cleared, loose '
        'items grouped like with like, cups and mugs stacked by size, papers '
        'in one neat stack, clothes folded in one pile, cables coiled into one '
        'box, the floor completely clear, and the remaining items contained in '
        'labelled baskets or boxes so the vertical space is used.';
  }

  String _pollinationsUrl(_ScanPlan plan, Uint8List? bytes) {
    final int seed = _photoSeed(bytes ?? Uint8List(0));
    final String where = plan.hasSetting ? plan.setting : 'room';
    final String prompt =
        'photorealistic tidy version of a $where after organising, items '
        'grouped and stacked, papers in one neat stack, cups stacked by size, '
        'cables coiled in a box, labelled baskets on the shelves, floor and '
        'surfaces clear, soft daylight';
    return 'https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}'
        '?width=1024&height=768&nologo=true&seed=$seed&model=flux';
  }

  // ---------------------------------------------------------------------
  // Offline demo coach
  // ---------------------------------------------------------------------

  int _photoSeed(Uint8List bytes) {
    int seed = 7;
    final int end = bytes.length < 2048 ? bytes.length : 2048;
    for (int i = 0; i < end; i++) {
      seed = (seed * 31 + bytes[i]) % 0x7FFFFFFF;
    }
    return seed;
  }

  _ScanPlan _demoPlan(Uint8List bytes) {
    final int seed = _photoSeed(bytes);
    final _DemoBank bank = _demoBanks[seed % _demoBanks.length];
    final int offset = seed % bank.suggestions.length;
    final List<_Suggestion> rotated = <_Suggestion>[
      ...bank.suggestions.skip(offset),
      ...bank.suggestions.take(offset),
    ];
    final int count = 2 + (seed % 3);
    return _ScanPlan(
      observations: bank.observations,
      suggestions: rotated.take(count).toList(),
      habits: bank.habits,
    );
  }

  static const List<_DemoBank> _demoBanks = <_DemoBank>[
    _DemoBank(
      observations: <String>[
        'Loose papers are covering the flat surface with no home yet.',
        'Folders and notebooks are stacked at odd angles.',
        'A few documents look like they still need an action.',
      ],
      suggestions: <_Suggestion>[
        _Suggestion(
          title: 'Sort the paper piles into action, file and recycle',
          detail:
              'Spread the loose sheets out and split them into three piles so '
              'nothing stays on the surface.',
          steps: <String>[
            'Gather every loose sheet into one pile on the clear part of the surface.',
            'Split that pile into three: action, file and recycle.',
            'Recycle the third pile, file the second in one labelled folder, and act on the first.',
          ],
        ),
        _Suggestion(
          title: 'File the loose documents in one labelled folder',
          detail:
              'Everything worth keeping goes into a single folder with a written '
              'label so it can be found in seconds.',
          steps: <String>[
            'Line the keepers up in date order.',
            'Slide them into one clear folder and write the label on the front.',
            'Stand the folder upright with the papers you use most in front of it.',
          ],
        ),
        _Suggestion(
          title: 'Stand the folders upright in a single row',
          detail:
              'Upright folders use the height of the shelf instead of its '
              'width and stop the pile from spreading again.',
          steps: <String>[
            'Collect every folder into one group.',
            'Stand them upright in a single row, biggest at the back.',
            'Keep only the folder in use at the front of the row.',
          ],
        ),
        _Suggestion(
          title: 'Clear the surface down to one working tray',
          detail:
              'A single tray gives every remaining sheet of paper a fixed home.',
          steps: <String>[
            'Take one small tray or shallow box.',
            'Drop the papers you touch daily into the tray.',
            'Store the tray at hand height and clear everything else off the surface.',
          ],
        ),
      ],
      habits: <String>[
        'Clear the surface before you leave the room.',
        'Every document gets one home: file it, act on it or bin it.',
        'Keep one tray for live papers and nothing more.',
      ],
    ),
    _DemoBank(
      observations: <String>[
        'Cups and mugs are sitting out on the surface.',
        'Plates and bowls are stacked loosely near the edge.',
        'The counter is doing double duty as a storage place.',
      ],
      suggestions: <_Suggestion>[
        _Suggestion(
          title: 'Stack the cups and mugs by size in one column',
          detail:
              'One column of stacked cups takes a quarter of the space and '
              'stops mugs knocking into each other.',
          steps: <String>[
            'Collect every cup and mug into one group.',
            'Stack them biggest at the bottom and smallest on top.',
            'Put the column on one shelf edge and keep it there.',
          ],
        ),
        _Suggestion(
          title: 'Wash the dishes in one batch',
          detail:
              'One batch of washing up finishes the pile faster than sorting '
              'dirty from clean.',
          steps: <String>[
            'Scrape the leftovers into the bin.',
            'Fill the sink with warm water and wash the whole stack.',
            'Dry and put the clean pieces away before you wipe the counter.',
          ],
        ),
        _Suggestion(
          title: 'Move the plates into one shallow stack',
          detail:
              'Plates stored flat in a single stack are easy to pull out and '
              'never topple.',
          steps: <String>[
            'Gather the plates from every surface.',
            'Stack them in one column in the rack or cupboard.',
            'Keep the plates you use every day at the front of the stack.',
          ],
        ),
        _Suggestion(
          title: 'Clear the counter down to one tray',
          detail:
              'A cleared counter gives you space to cook and to notice the '
              'next pile early.',
          steps: <String>[
            'Put every item that is not for cooking into one tray or box.',
            'Carry the tray to the shelf where it belongs.',
            'Wipe the counter and leave the middle completely empty.',
          ],
        ),
      ],
      habits: <String>[
        'Dishes go back to the same shelf every time.',
        'Keep the counter clear so you can see the mess early.',
        'Empty the drying rack before you start a new batch.',
      ],
    ),
    _DemoBank(
      observations: <String>[
        'Clothes are resting on the floor in loose piles.',
        'Cables are tangled and run across the walking area.',
        'A few items are only kept because there is no box for them.',
      ],
      suggestions: <_Suggestion>[
        _Suggestion(
          title: 'Corral every cable into one box',
          detail:
              'Tangled cables take more space than they need and are easy to '
              'lose under the furniture.',
          steps: <String>[
            'Pull every charger and cable out of the tangle.',
            'Coil each one and tie it with a band or a tie.',
            'Drop the coils into one labelled box and keep the box in one drawer.',
          ],
        ),
        _Suggestion(
          title: 'Fold the clothes and line them up in one stack',
          detail:
              'Folded clothes in one stack look finished and take half the '
              'space of a loose pile.',
          steps: <String>[
            'Spread the clothes out on the bed or the floor.',
            'Fold each item and stack it in the order you wear it.',
            'Keep the three items for this week on top of the stack.',
          ],
        ),
        _Suggestion(
          title: 'Clear the floor into one walking lane',
          detail:
              'A clear floor is the fastest way to make a small space feel '
              'bigger and safer.',
          steps: <String>[
            'Sweep every loose item into one pile in the middle of the floor.',
            'Sort the pile into keep, relocate and bin.',
            'Relocate the keepers and leave the floor empty from wall to wall.',
          ],
        ),
        _Suggestion(
          title: 'Give every odds and ends a labelled home',
          detail:
              'Items without a home always end up back on the floor, so give '
              'them a box.',
          steps: <String>[
            'Choose one small box for the loose odds and ends.',
            'Label the front of the box.',
            'Fill the box and put it back in the same place every time.',
          ],
        ),
      ],
      habits: <String>[
        'Nothing stays on the floor overnight.',
        'Cables are coiled and boxed the moment they are unpacked.',
        'Fold clothes straight into the stack, never onto a chair.',
      ],
    ),
  ];

  // ---------------------------------------------------------------------
  // Chat stage
  // ---------------------------------------------------------------------

  void _buildChatLines() {
    final _ScanPlan plan = _plan;
    final List<_ChatLine> lines = <_ChatLine>[];
    lines.add(const _ChatLine(text: 'This is the photo I am looking at.', isPhoto: true));
    lines.add(_ChatLine(text: _introLine()));
    for (final String observation in plan.observations) {
      lines.add(_ChatLine(text: observation));
    }
    for (int i = 0; i < plan.suggestions.length; i++) {
      final _Suggestion suggestion = plan.suggestions[i];
      lines.add(_ChatLine(text: suggestion.title, isHeading: true));
      if (suggestion.detail.isNotEmpty) {
        lines.add(_ChatLine(text: suggestion.detail));
      }
      if (suggestion.steps.isNotEmpty) {
        lines.add(_ChatLine(text: 'How to do it: ${suggestion.steps.join(' -> ')}'));
      }
      if (i < plan.suggestions.length - 1) {
        lines.add(
          _ChatLine(
            text: _interjections[i % _interjections.length],
            isUser: true,
          ),
        );
      }
    }
    lines.add(
      const _ChatLine(
        text: 'That is the whole plan. Start with the first action, then take '
            'another photo afterwards and we will check how the space looks.',
      ),
    );
    setState(() {
      _lines = lines;
      _revealed = 1;
      _stage = _ScanStage.chat;
    });
    _scrollToBottom();
  }

  String _introLine() {
    final _ScanPlan plan = _plan;
    if (_usedFallback) {
      return 'Demo mode: I am coaching from my offline tidy play book, so '
          'these actions come from a small library instead of this exact '
          'photo. Tap the key icon in the top bar to add your own Gemini key '
          'and get photo specific analysis plus a photoreal after-shot.';
    }
    final String where = plan.hasSetting ? plan.setting : 'this space';
    final int count = plan.suggestions.length;
    if (plan.hasTidiness) {
      return 'Looking at the $where, I would call it ${_titleCase(plan.tidiness)}. '
          'Here are $count concrete actions, each one something you can do with '
          'your hands right now.';
    }
    return 'Looking at the $where, here is what stands out and the $count '
        'concrete actions for it.';
  }

  void _revealNext() {
    setState(() {
      if (_revealed < _lines.length) _revealed++;
    });
    _scrollToBottom();
  }

  void _openResult() {
    setState(() {
      _stage = _ScanStage.result;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_chatScroll.hasClients) return;
      _chatScroll.animateTo(
        _chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ---------------------------------------------------------------------
  // Result stage helpers
  // ---------------------------------------------------------------------

  Future<void> _copyPlan() async {
    await Clipboard.setData(ClipboardData(text: _planDigest()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan copied')),
    );
  }

  String _planDigest() {
    final _ScanPlan plan = _plan;
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Stuff Organiser - tidy plan');
    if (plan.hasSetting) buffer.writeln('Setting: ${plan.setting}');
    if (plan.hasTidiness) {
      buffer.writeln('Mess level: ${_titleCase(plan.tidiness)}');
    }
    buffer.writeln();
    if (plan.observations.isNotEmpty) {
      buffer.writeln('What the coach saw');
      for (final String observation in plan.observations) {
        buffer.writeln('- $observation');
      }
      buffer.writeln();
    }
    buffer.writeln('Step-by-step plan');
    int index = 1;
    for (final _Suggestion suggestion in plan.suggestions) {
      buffer.writeln('$index. ${suggestion.title}');
      if (suggestion.detail.isNotEmpty) {
        buffer.writeln('   ${suggestion.detail}');
      }
      for (final String step in suggestion.steps) {
        buffer.writeln('   - $step');
      }
      index++;
    }
    buffer.writeln();
    if (plan.habits.isNotEmpty) {
      buffer.writeln('Keep it tidy');
      for (final String habit in plan.habits) {
        buffer.writeln('- $habit');
      }
    }
    buffer.writeln();
    buffer.writeln(
      _afterReal
          ? 'After-shot: photorealistic image generated from this photo.'
          : 'After-shot: AI concept sketch built from the setting text.',
    );
    if (_usedFallback) {
      buffer.writeln(
        '(Offline demo plan. Add a Gemini key in the top bar to analyse this '
        'exact photo and generate a photoreal after-shot.)',
      );
    }
    return buffer.toString();
  }

  void _resetFlow() {
    _runId++;
    setState(() {
      _photoBytes = null;
      _lines = <_ChatLine>[];
      _revealed = 0;
      _stage = _ScanStage.pick;
      _plan = const _ScanPlan(
        observations: <String>[],
        habits: <String>[],
      );
      _afterBytes = null;
      _afterUrl = null;
      _afterReal = false;
      _afterLoading = false;
      _usedFallback = false;
      _error = null;
      _analyzing = false;
    });
  }

  // ---------------------------------------------------------------------
  // API key
  // ---------------------------------------------------------------------

  Future<void> _openApiKeyDialog() async {
    final TextEditingController controller =
        TextEditingController(text: _apiKey ?? '');
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Gemini API key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Optional. The key stays on this device and is used for photo '
                'analysis and for generating the after-tidying picture.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: 'API key',
                  hintText: 'AIza...',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(_clearSentinel),
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (!mounted) return;
    if (result == null) return;

    if (result == _clearSentinel || result.isEmpty) {
      await widget.prefs.remove(_prefsKey);
      if (!mounted) return;
      setState(() {
        _apiKey = null;
      });
      return;
    }

    await widget.prefs.setString(_prefsKey, result);
    if (!mounted) return;
    setState(() {
      _apiKey = result;
    });
    if (_photoBytes != null) {
      await _analyze();
    }
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stageTitle),
        actions: <Widget>[
          IconButton(
            tooltip: 'Gemini API key',
            icon: Icon(
              _apiKey == null || _apiKey!.isEmpty
                  ? Icons.vpn_key_outlined
                  : Icons.vpn_key,
            ),
            onPressed: _openApiKeyDialog,
          ),
        ],
      ),
      body: switch (_stage) {
        _ScanStage.pick => _buildPick(context),
        _ScanStage.chat => _buildChat(context),
        _ScanStage.result => _buildResult(context),
      },
    );
  }

  Widget _buildPick(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool live = _apiKey != null && _apiKey!.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: <Widget>[
        Center(
          child: MascotWidget(
            variant: widget.mascot,
            pack: widget.pack,
            size: 120,
            mood: MascotMood.happy,
            celebrationTick: 0,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Scan your room',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Photograph a messy table, desk, shelf, floor, bed or counter. The '
          'coach looks at the real photo, tells you which surfaces are in '
          'shot and how messy they are, then gives you concrete actions for '
          'the things it can actually see.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Chip(
            avatar: Icon(
              live ? Icons.bolt : Icons.science_outlined,
              size: 18,
            ),
            label: Text(live ? 'Live analysis' : 'Demo mode'),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    _analyzing ? null : () => _capture(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _analyzing ? null : () => _capture(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
        if (_analyzing) ...<Widget>[
          const SizedBox(height: 20),
          const LinearProgressIndicator(),
          const SizedBox(height: 10),
          Text('Analysing the photo...', style: theme.textTheme.bodySmall),
        ],
        if (!live) ...<Widget>[
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.vpn_key_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tip: tap the key icon in the top bar to add your own '
                      'Gemini key. With a key the coach analyses this exact '
                      'photo, reports the setting and the mess level, and '
                      'generates a photoreal after-tidying picture.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_error != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChat(BuildContext context) {
    final List<_ChatLine> visible = _lines.take(_revealed).toList();
    final bool allRevealed = _revealed >= _lines.length;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            controller: _chatScroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            itemCount: visible.length,
            itemBuilder: (BuildContext context, int index) =>
                _bubble(context, visible[index]),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: allRevealed
                ? FilledButton.icon(
                    onPressed: _openResult,
                    icon: const Icon(Icons.checklist_rounded),
                    label: const Text('Show my tidy plan'),
                  )
                : OutlinedButton.icon(
                    onPressed: _revealNext,
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('Next'),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _bubble(BuildContext context, _ChatLine line) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    if (line.isPhoto) {
      final Uint8List? bytes = _photoBytes;
      if (bytes == null) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              bytes,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }
    final bool isUser = line.isUser;
    final Widget bubble = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? scheme.primaryContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        line.text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color:
              isUser ? scheme.onPrimaryContainer : scheme.onSecondaryContainer,
          fontWeight: line.isHeading ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
    if (isUser || !line.isHeading) {
      return Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MascotWidget(
              variant: widget.mascot,
              pack: widget.pack,
              size: 36,
              celebrationTick: 0,
            ),
          ),
          Flexible(child: bubble),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Uint8List? bytes = _photoBytes;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: bytes == null
                  ? Container(
                      width: 88,
                      height: 88,
                      color: theme.colorScheme.surfaceContainerHighest,
                    )
                  : Image.memory(
                      bytes,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Your tidy plan',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_plan.suggestions.length} concrete actions for this space',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _chipsRow(context),
        const SizedBox(height: 14),
        _afterCard(context),
        const SizedBox(height: 14),
        _notesCard(context),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyPlan,
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy all'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _resetFlow,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Scan another room'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chipsRow(BuildContext context) {
    final _ScanPlan plan = _plan;
    if (!plan.hasSetting && !plan.hasTidiness) {
      return const SizedBox.shrink();
    }
    final double maxWidth = MediaQuery.of(context).size.width - 48;
    final List<Widget> chips = <Widget>[];
    if (plan.hasSetting) {
      chips.add(
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Chip(
            avatar: const Icon(Icons.place_outlined, size: 18),
            label: Text(
              'Setting: ${plan.setting}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    if (plan.hasTidiness) {
      chips.add(
        Chip(
          avatar: const Icon(Icons.spa_outlined, size: 18),
          label: Text('Mess level: ${_titleCase(plan.tidiness)}'),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _afterCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Card(
      // The theme pack is part of the key so a different pack rebuilds the card.
      key: ValueKey<Object>(widget.pack),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _afterImage(scheme),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'After tidying',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_afterCaption(), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _afterCaption() {
    if (_afterLoading) {
      return 'Generating the after-tidying picture from your photo...';
    }
    if (_afterReal) {
      return 'After tidying - photorealistic version generated from this '
          'exact photo.';
    }
    return 'After tidying - AI concept sketch built from the setting. Add a '
        'Gemini key for a photorealistic after-shot of your exact room.';
  }

  Widget _afterImage(ColorScheme scheme) {
    final Uint8List? bytes = _afterBytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) =>
            _conceptPlaceholder(scheme),
      );
    }
    final String? url = _afterUrl;
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? progress,
        ) {
          if (progress == null) return child;
          return _loadingPlaceholder(scheme);
        },
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) =>
            _conceptPlaceholder(scheme),
      );
    }
    return _loadingPlaceholder(scheme);
  }

  Widget _loadingPlaceholder(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: CircularProgressIndicator(color: scheme.primary),
      ),
    );
  }

  Widget _conceptPlaceholder(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[scheme.secondaryContainer, scheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.auto_awesome,
              size: 32,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(height: 8),
            Text(
              'Concept preview',
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notesCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final _ScanPlan plan = _plan;

    final List<Widget> observationWidgets = plan.observations.isEmpty
        ? <Widget>[
            Text('No observations recorded.', style: theme.textTheme.bodySmall),
          ]
        : plan.observations
            .map(
              (String observation) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        observation,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList();

    final List<Widget> habitWidgets = plan.habits
        .map(
          (String habit) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.repeat, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(habit, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'What the coach saw',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...observationWidgets,
            const Divider(height: 24),
            Text(
              'Step-by-step plan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < plan.suggestions.length; i++)
              _suggestionBlock(context, i + 1, plan.suggestions[i]),
            const Divider(height: 24),
            Text(
              'Keep it tidy',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...habitWidgets,
            const SizedBox(height: 12),
            Text(
              _afterReal
                  ? 'After-shot: photorealistic image generated from this photo.'
                  : 'After-shot: AI concept sketch built from the setting text.',
              style: theme.textTheme.bodySmall,
            ),
            if (_usedFallback) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'Demo plan: add a Gemini key in the top bar to analyse this '
                'exact photo and generate a photoreal after-shot.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _suggestionBlock(
    BuildContext context,
    int number,
    _Suggestion suggestion,
  ) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$number. ${suggestion.title}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (suggestion.detail.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(suggestion.detail, style: theme.textTheme.bodyMedium),
          ],
          if (suggestion.steps.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            for (final String step in suggestion.steps)
              Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('- '),
                    Expanded(
                      child: Text(step, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
