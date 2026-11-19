import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../services/plan_engine.dart';
import '../state/app_state.dart';

/// Screen 3: log an item in at most two taps (chip, then Add).
class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final TextEditingController _nameController = TextEditingController();
  ItemCategory _category = ItemCategory.household;
  PaperAction _action = PaperAction.sort;
  int _quantity = 1;
  String? _spaceId;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectPreset(QuickAddPreset preset) {
    setState(() {
      _nameController.text = preset.label;
      _category = preset.category;
      if (preset.paperAction != null) _action = preset.paperAction!;
      _spaceId = null;
    });
  }

  /// Guards against a space being deleted while this screen is open.
  String? _validatedSelectedSpace(AppState state) {
    final String? selected = _spaceId;
    if (selected != null && state.spaceById(selected) != null) return selected;
    return null;
  }

  String? _effectiveSpace(AppState state) {
    final String? selected = _validatedSelectedSpace(state);
    if (selected != null) return selected;
    return state.suggestSpaceId(_nameController.text, _category);
  }

  Future<void> _add(AppState state) async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give it a name first')),
      );
      return;
    }

    // The space the item would really land in: picked one, else suggestion.
    // Matches the resolution inside AppState.addItem.
    final String? effectiveSpaceId = _validatedSelectedSpace(state) ??
        state.suggestSpaceId(name, _category);

    // v0.3 duplicate guard: same normalised name already in that space?
    final Item? duplicate = state.findDuplicate(name, effectiveSpaceId);
    if (duplicate != null) {
      final _DuplicateChoice? choice =
          await _showDuplicateDialog(state, duplicate, effectiveSpaceId);
      if (!mounted) return;
      if (choice == null || choice == _DuplicateChoice.cancel) return;
      if (choice == _DuplicateChoice.merge) {
        await _mergeDuplicate(state, duplicate, effectiveSpaceId);
        return;
      }
      // _DuplicateChoice.addAnyway falls through to the regular add below.
    }

    setState(() => _saving = true);
    try {
      final Item item = await state.addItem(
        name: name,
        category: _category,
        quantity: _quantity,
        spaceId: _validatedSelectedSpace(state),
        paperAction: _category == ItemCategory.paper ? _action : null,
      );
      if (!mounted) return;
      final String spaceName = state.spaceById(item.spaceId)?.name ?? 'your list';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name added to $spaceName. Plan updated.')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Folds a would-be duplicate into the entry that is already stored.
  Future<void> _mergeDuplicate(
    AppState state,
    Item duplicate,
    String? effectiveSpaceId,
  ) async {
    setState(() => _saving = true);
    try {
      final Item? merged = await state.mergeIntoItem(duplicate, _quantity);
      if (!mounted) return;
      final int total = merged?.quantity ?? duplicate.quantity + _quantity;
      final String spaceName =
          state.spaceById(effectiveSpaceId ?? '')?.name ?? 'your list';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${duplicate.name} now x$total in $spaceName')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Asks how to handle a duplicate. Dismissing the dialog counts as cancel.
  Future<_DuplicateChoice?> _showDuplicateDialog(
    AppState state,
    Item duplicate,
    String? effectiveSpaceId,
  ) {
    final String place =
        state.spaceById(effectiveSpaceId ?? '')?.name ?? 'your list';
    return showDialog<_DuplicateChoice>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text('Already in $place'),
        content: Text(
          '${duplicate.name} is already in $place (x${duplicate.quantity}). '
          'Increase the count, or add it as a separate entry?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_DuplicateChoice.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_DuplicateChoice.addAnyway),
            child: const Text('Add anyway'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_DuplicateChoice.merge),
            child: const Text('Increase count'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final ThemeData theme = Theme.of(context);
    final String? effectiveSpace = _effectiveSpace(state);
    final bool hasSpaces = state.spaces.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick add'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            Text('Tap a chip, then Add. That is it.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'What is it?',
                hintText: 'Cup, jeans, paper pile...',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PlanEngine.presets.map((QuickAddPreset preset) {
                final bool selected =
                    _nameController.text.trim() == preset.label && _category == preset.category;
                return ChoiceChip(
                  label: Text('${preset.emoji}  ${preset.label}'),
                  selected: selected,
                  onSelected: (_) => _selectPreset(preset),
                );
              }).toList(),
            ),
            if (_category == ItemCategory.paper) ...<Widget>[
              const SizedBox(height: 20),
              Text('What will you do with it?', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaperAction.values.map((PaperAction action) {
                  return ChoiceChip(
                    label: Text(action.label),
                    selected: _action == action,
                    onSelected: (_) => setState(() => _action = action),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Text(_action.hint, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Text('How many?', style: theme.textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_quantity', style: theme.textTheme.titleMedium),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.auto_awesome_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: hasSpaces ? effectiveSpace : null,
                          isExpanded: true,
                          hint: Text(hasSpaces ? 'Pick a space' : 'Create a space first'),
                          items: state.spaces
                              .map((space) => DropdownMenuItem<String>(
                                    value: space.id,
                                    child: Text('${space.emoji}  ${space.name}'),
                                  ))
                              .toList(),
                          onChanged: (String? value) => setState(() => _spaceId = value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suggestion: ${state.spaceById(effectiveSpace ?? '')?.name ?? 'add a space to get one'}.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (!hasSpaces || _saving) ? null : () => _add(state),
                icon: const Icon(Icons.add_task),
                label: Text(_saving ? 'Adding...' : 'Add to plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The options offered when the item already exists in the target space.
enum _DuplicateChoice { merge, addAnyway, cancel }
