import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'plan_screen_views.dart';

/// Screen 5: the Tidy Plan - a user-editable to-do list.
/// Large parts (rooms and areas) are renamable, task lines collapse to hide
/// an optional details box, every task has a tick-off checkbox, and the
/// collapse arrows use the icon the user picked. Everything saves on the
/// device automatically.
/// v0.8.16: first runs start with an empty list (no sample part), and a
/// corrupt store is surfaced instead of silently looking empty.

class TidyTask {
  TidyTask({required this.id, required this.text, this.details = '', this.done = false});

  factory TidyTask.fromJson(Map<String, dynamic> json) {
    return TidyTask(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      details: json['details'] as String? ?? '',
      done: json['done'] as bool? ?? false,
    );
  }

  final String id;
  String text;
  String details;
  bool done;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'details': details,
      'done': done,
    };
  }
}

class TidyPart {
  TidyPart({required this.id, required this.name, required this.tasks});

  factory TidyPart.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawTasks = json['tasks'] as List<dynamic>? ?? <dynamic>[];
    return TidyPart(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tasks: rawTasks
          .map((dynamic entry) => TidyTask.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  String name;
  final List<TidyTask> tasks;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'tasks': tasks.map((TidyTask task) => task.toJson()).toList(),
    };
  }
}

class _ArrowStyle {
  const _ArrowStyle(this.id, this.label, this.openIcon, this.closedIcon);

  final String id;
  final String label;
  final IconData openIcon;
  final IconData closedIcon;
}

const List<_ArrowStyle> _arrowStyles = <_ArrowStyle>[
  _ArrowStyle('chevron', 'Chevron', Icons.keyboard_arrow_down, Icons.keyboard_arrow_right),
  _ArrowStyle('triangle', 'Triangle', Icons.arrow_drop_down, Icons.change_history),
  _ArrowStyle('plusminus', 'Plus / minus', Icons.remove, Icons.add),
  _ArrowStyle('arrow', 'Arrow', Icons.arrow_downward, Icons.arrow_forward),
  _ArrowStyle('disc', 'Disc', Icons.fiber_manual_record, Icons.radio_button_unchecked),
];

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  static const String _dataKey = 'tidy_plan_todo_v1';
  static const String _arrowKey = 'tidy_arrow_style';
  static int _idCounter = 0;

  final Set<String> _expandedParts = <String>{};
  final Set<String> _expandedTasks = <String>{};
  final Map<String, TextEditingController> _detailControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _addTaskControllers =
      <String, TextEditingController>{};

  List<TidyPart> _parts = <TidyPart>[];
  String _arrowId = 'chevron';
  bool _loaded = false;

  /// v0.8.16 (TC-11): true when the stored plan data exists but cannot be
  /// parsed - the tab says so instead of silently looking empty.
  bool _corruptStore = false;

  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _detailControllers.values) {
      controller.dispose();
    }
    for (final TextEditingController controller in _addTaskControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    if (!mounted) {
      return;
    }
    final String raw = prefs.getString(_dataKey) ?? '';
    final String arrow = prefs.getString(_arrowKey) ?? 'chevron';
    setState(() {
      _arrowId = _arrowStyles.any((_ArrowStyle style) => style.id == arrow) ? arrow : 'chevron';
      _parts = _decode(raw);
      _loaded = true;
    });
  }

  List<TidyPart> _decode(String raw) {
    _corruptStore = false;
    if (raw.trim().isEmpty) {
      // v0.8.16: first-time users start with an empty plan - no sample
      // part (Herrick's empty-first-run directive). Scanned rooms add
      // their parts here automatically.
      return <TidyPart>[];
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      final List<dynamic> list = decoded as List<dynamic>;
      return list
          .map((dynamic entry) => TidyPart.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // v0.8.16 (TC-11): the same honest wording as the scan-side save.
      _corruptStore = true;
      return <TidyPart>[];
    }
  }

  Future<void> _persist() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) {
      return;
    }
    final String encoded =
        jsonEncode(_parts.map((TidyPart part) => part.toJson()).toList());
    await prefs.setString(_dataKey, encoded);
    await prefs.setString(_arrowKey, _arrowId);
    // v0.8.16 (TC-11): any successful save replaces a corrupt store, so
    // the banner clears with the state it describes.
    if (_corruptStore) {
      setState(() {
        _corruptStore = false;
      });
    }
  }

  String _newId() {
    _idCounter++;
    return 't${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
  }

  _ArrowStyle get _arrow {
    for (final _ArrowStyle style in _arrowStyles) {
      if (style.id == _arrowId) {
        return style;
      }
    }
    return _arrowStyles.first;
  }

  TextEditingController _detailController(TidyTask task) {
    return _detailControllers.putIfAbsent(
      task.id,
      () => TextEditingController(text: task.details),
    );
  }

  TextEditingController _addTaskController(String partId) {
    return _addTaskControllers.putIfAbsent(partId, () => TextEditingController());
  }

  void _disposeControllersForPart(TidyPart part) {
    for (final TidyTask task in part.tasks) {
      final TextEditingController? detail = _detailControllers.remove(task.id);
      detail?.dispose();
    }
    final TextEditingController? add = _addTaskControllers.remove(part.id);
    add?.dispose();
  }

  /// v0.8.16: setState hook for the views part file - extensions cannot
  /// call the protected member directly, so they call this instead.
  void replan(VoidCallback fn) {
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tidy plan'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Choose the collapse arrow icon',
            icon: Icon(_arrow.openIcon),
            onPressed: _pickArrow,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Your to-do list. Rename a part, collapse a line, tick things off.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (_corruptStore)
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'The saved plan data on this device could not be read, so this list is showing empty. Nothing was deleted - the next save replaces it.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                if (_parts.isEmpty && !_corruptStore)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Nothing here yet. Scan a room and its tidy plan lands here automatically.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                for (final TidyPart part in _parts)
                  _buildPartCard(part, theme),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addPart,
                  icon: const Icon(Icons.add),
                  label: const Text('Add part'),
                ),
              ],
            ),
    );
  }
}
