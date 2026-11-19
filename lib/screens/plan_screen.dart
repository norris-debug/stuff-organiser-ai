import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen 5: the Tidy Plan - a user-editable to-do list.
/// Large parts (rooms and areas) are renamable, task lines collapse to hide
/// an optional details box, every task has a tick-off checkbox, and the
/// collapse arrows use the icon the user picked. Everything saves on the
/// device automatically.

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
    if (raw.trim().isEmpty) {
      return <TidyPart>[
        TidyPart(
          id: 'part-sample',
          name: 'Dining room',
          tasks: <TidyTask>[
            TidyTask(id: 'task-sample', text: 'Put the tissue paper back onto the box'),
          ],
        ),
      ];
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      final List<dynamic> list = decoded as List<dynamic>;
      return list
          .map((dynamic entry) => TidyPart.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
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

  Future<void> _renamePart(TidyPart part) async {
    final TextEditingController controller = TextEditingController(text: part.name);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Rename part'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Part name',
              hintText: 'Dining room',
            ),
          ),
          actions: <Widget>[
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
    controller.dispose();
    if (newName == null || newName.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      part.name = newName;
    });
    await _persist();
  }

  Future<void> _deletePart(TidyPart part) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete part'),
          content: Text('Delete ${part.name} and its tasks?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _parts.removeWhere((TidyPart candidate) => candidate.id == part.id);
      _expandedParts.remove(part.id);
    });
    for (final TidyTask task in part.tasks) {
      _expandedTasks.remove(task.id);
    }
    _disposeControllersForPart(part);
    await _persist();
  }

  Future<void> _addPart() async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('New part'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Part name',
              hintText: 'Dining room',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) {
      return;
    }
    final TidyPart part = TidyPart(id: _newId(), name: name, tasks: <TidyTask>[]);
    setState(() {
      _parts.add(part);
      _expandedParts.add(part.id);
    });
    await _persist();
  }

  void _addTask(TidyPart part) {
    final TextEditingController? controller = _addTaskControllers[part.id];
    final String text = controller?.text.trim() ?? '';
    if (text.isEmpty) {
      return;
    }
    setState(() {
      part.tasks.add(TidyTask(id: _newId(), text: text));
    });
    controller?.clear();
    _persist();
  }

  Future<void> _deleteTask(TidyTask task) async {
    for (final TidyPart part in _parts) {
      if (part.tasks.contains(task)) {
        setState(() {
          part.tasks.remove(task);
        });
        break;
      }
    }
    _expandedTasks.remove(task.id);
    final TextEditingController? detail = _detailControllers.remove(task.id);
    detail?.dispose();
    await _persist();
  }

  Future<void> _pickArrow() async {
    final String? picked = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Collapse arrow icon'),
          children: <Widget>[
            for (final _ArrowStyle style in _arrowStyles)
              RadioListTile<String>(
                value: style.id,
                groupValue: _arrowId,
                title: Row(
                  children: <Widget>[
                    Icon(style.openIcon),
                    const SizedBox(width: 12),
                    Text(style.label),
                  ],
                ),
                onChanged: (String? value) => Navigator.of(dialogContext).pop(value),
              ),
          ],
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _arrowId = picked;
    });
    await _persist();
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

  Widget _buildPartCard(TidyPart part, ThemeData theme) {
    final bool expanded = _expandedParts.contains(part.id);
    final int doneCount = part.tasks.where((TidyTask task) => task.done).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedParts.remove(part.id);
                } else {
                  _expandedParts.add(part.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    expanded ? _arrow.openIcon : _arrow.closedIcon,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(part.name, style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    '$doneCount/${part.tasks.length}',
                    style: theme.textTheme.labelSmall,
                  ),
                  IconButton(
                    tooltip: 'Rename part',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _renamePart(part),
                  ),
                  IconButton(
                    tooltip: 'Delete part',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _deletePart(part),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            ..._buildPartBody(part, theme),
        ],
      ),
    );
  }

  List<Widget> _buildPartBody(TidyPart part, ThemeData theme) {
    return <Widget>[
      const Divider(height: 1),
      if (part.tasks.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'No tasks yet - add one below.',
            style: theme.textTheme.bodySmall,
          ),
        )
      else
        ...<Widget>[
          for (final TidyTask task in part.tasks) _buildTaskRow(task, theme),
        ],
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _addTaskController(part.id),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (String value) => _addTask(part),
                decoration: const InputDecoration(
                  hintText: 'New task, e.g. put the tissue paper back onto the box',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Add task',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addTask(part),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildTaskRow(TidyTask task, ThemeData theme) {
    final bool open = _expandedTasks.contains(task.id);
    return Column(
      children: <Widget>[
        InkWell(
          onTap: () {
            setState(() {
              if (open) {
                _expandedTasks.remove(task.id);
              } else {
                _expandedTasks.add(task.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: <Widget>[
                Checkbox(
                  value: task.done,
                  onChanged: (bool? value) {
                    setState(() {
                      task.done = value ?? false;
                    });
                    _persist();
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.text,
                    style: task.done
                        ? theme.textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.outline,
                          )
                        : theme.textTheme.bodyMedium,
                  ),
                ),
                Icon(
                  open ? _arrow.openIcon : _arrow.closedIcon,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
                IconButton(
                  tooltip: 'Delete task',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _deleteTask(task),
                ),
              ],
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
            child: TextField(
              controller: _detailController(task),
              maxLines: null,
              onChanged: (String value) {
                task.details = value;
                _persist();
              },
              decoration: const InputDecoration(
                hintText: 'Details (optional)',
                filled: true,
                border: InputBorder.none,
              ),
            ),
          ),
      ],
    );
  }
}
