part of 'plan_screen.dart';

/// v0.8.16: the plan tab's dialogs and view builders split into a part
/// file so every file stays push- and verify-sized. Behavior is unchanged
/// except where noted.
extension _PlanScreenViews on _PlanScreenState {
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