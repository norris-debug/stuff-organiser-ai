import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../models/space.dart';
import '../state/app_state.dart';

/// Screen 4: one space, drag-and-drop item grid.
///
/// v0.8.16 redesign (Herrick's directive): the venue page lists the
/// room's items straight from the scan, tap = select, and a bottom
/// "Finish organizing" button clears the selection. The per-item
/// three-dots delete menu is gone, and the "Drop in [venue]" chips now
/// open that venue's page on tap (they stay drag targets for
/// drag-and-drop moves).
class SpaceDetailScreen extends StatefulWidget {
  const SpaceDetailScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  final Set<String> _selected = <String>{};

  void _dropOnItem(AppState state, Item dragged, Item target) {
    if (dragged.id == target.id) return;
    if (dragged.spaceId == target.spaceId) {
      state.reorderItem(dragged.id, target.id);
    } else {
      state.moveItemToSpace(dragged.id, target.spaceId, beforeItemId: target.id);
    }
  }

  void _toggleSelected(String itemId) {
    setState(() {
      if (!_selected.remove(itemId)) {
        _selected.add(itemId);
      }
    });
  }

  /// v0.8.16: the selected items are cleared from the space - the
  /// three-dots delete menu is replaced by multi-select plus this one
  /// bottom button.
  Future<void> _finishOrganizing(AppState state) async {
    final List<String> ids = _selected.toList();
    if (ids.isEmpty) return;
    for (final String id in ids) {
      await state.deleteItem(id);
    }
    if (!mounted) return;
    setState(() {
      _selected.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Removed ${ids.length} item${ids.length == 1 ? '' : 's'} - nice work.',
        ),
      ),
    );
  }

  /// v0.3: changes the planned action of a paper pile after creation.
  Future<void> _editPaperAction(
    BuildContext context,
    AppState state,
    Item item,
  ) async {
    final PaperAction? selected = await showModalBottomSheet<PaperAction>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Planned action for ${item.name}',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final PaperAction action in PaperAction.values)
              ListTile(
                leading: Icon(_paperActionIcon(action)),
                title: Text(action.label),
                subtitle: Text(action.hint),
                trailing:
                    item.paperAction == action ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop(action),
              ),
          ],
        ),
      ),
    );
    if (selected == null || selected == item.paperAction) return;
    await state.setPaperAction(item.id, selected);
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final ThemeData theme = Theme.of(context);
    final Space? space = state.spaceById(widget.spaceId);

    if (space == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Space')),
        body: const Center(child: Text('This space no longer exists.')),
      );
    }

    // Selections pointing at deleted items cannot linger.
    _selected.retainAll(state.items.map((Item item) => item.id));

    final List<Item> spaceItems = state.items
        .where((Item item) => item.spaceId == widget.spaceId)
        .toList()
      ..sort((Item a, Item b) => a.order.compareTo(b.order));

    final List<Space> otherSpaces = state.spaces
        .where((Space s) => s.id != widget.spaceId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${space.emoji}  ${space.name}'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String value) async {
              if (value == 'rename') {
                await _rename(context, state, space);
              } else if (value == 'delete') {
                await state.deleteSpace(space.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'rename', child: Text('Rename space')),
              PopupMenuItem<String>(value: 'delete', child: Text('Delete space')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${spaceItems.length} item${spaceItems.length == 1 ? '' : 's'} · '
                      '${state.looseInSpace(widget.spaceId)} loose',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Text('Tap = select · Hold + drag = move', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            if (otherSpaces.isNotEmpty)
              SizedBox(
                height: 62,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: otherSpaces
                      .map((Space target) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: DragTarget<Item>(
                              onAcceptWithDetails: (DragTargetDetails<Item> details) {
                                state.moveItemToSpace(details.data.id, target.id);
                              },
                              builder: (
                                BuildContext context,
                                List<Item?> candidate,
                                List<dynamic> rejected,
                              ) {
                                final bool active = candidate.isNotEmpty;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: active
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme.surface,
                                    border: Border.all(color: theme.colorScheme.outlineVariant),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Text(target.emoji),
                                      const SizedBox(width: 8),
                                      // v0.8.16: the chip opens the target
                                      // venue's page on tap (it used to do
                                      // nothing); it stays a drag target for
                                      // drag-and-drop moves.
                                      InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => SpaceDetailScreen(spaceId: target.id),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          child: Text(
                                            'Drop in ${target.name}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
            Expanded(
              child: spaceItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('Nothing unpacked here yet.', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 6),
                          Text(
                            'Scan this room again or use Quick add to log something.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: spaceItems.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Item item = spaceItems[index];
                        return _DraggableItemTile(
                          item: item,
                          selected: _selected.contains(item.id),
                          onToggle: () => _toggleSelected(item.id),
                          onAccept: (Item dragged) => _dropOnItem(state, dragged, item),
                          onEditPaperAction: () => _editPaperAction(context, state, item),
                        );
                      },
                    ),
            ),
            if (_selected.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _finishOrganizing(state),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text('Finish organizing (${_selected.length})'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, AppState state, Space space) async {
    final TextEditingController controller =
        TextEditingController(text: space.name);
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Rename space'),
        content: TextField(controller: controller, autofocus: true),
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
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) {
      await state.renameSpace(space.id, name);
    }
  }
}

class _DraggableItemTile extends StatelessWidget {
  const _DraggableItemTile({
    required this.item,
    required this.selected,
    required this.onToggle,
    required this.onAccept,
    required this.onEditPaperAction,
  });

  final Item item;
  final bool selected;
  final VoidCallback onToggle;
  final ValueChanged<Item> onAccept;
  final VoidCallback onEditPaperAction;

  @override
  Widget build(BuildContext context) {
    final Widget tile = _ItemTile(
      item: item,
      selected: selected,
      onToggle: onToggle,
      onEditPaperAction: onEditPaperAction,
    );
    return LongPressDraggable<Item>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 160,
          height: 150,
          child: _ItemTile(
            item: item,
            selected: false,
            onToggle: () {},
            onEditPaperAction: () {},
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: DragTarget<Item>(
        onAcceptWithDetails: (DragTargetDetails<Item> details) => onAccept(details.data),
        builder: (BuildContext context, List<Item?> candidate, List<dynamic> rejected) {
          final bool active = candidate.isNotEmpty;
          return AnimatedScale(
            scale: active ? 1.06 : 1,
            duration: const Duration(milliseconds: 140),
            child: tile,
          );
        },
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.selected,
    required this.onToggle,
    required this.onEditPaperAction,
  });

  final Item item;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onEditPaperAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool organized = item.status == ItemStatus.organized;

    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : organized
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(item.isPaper ? '📄' : '📦', style: const TextStyle(fontSize: 20)),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary)
                  else if (organized)
                    Icon(Icons.check_circle_outline, size: 18, color: theme.colorScheme.outline),
                ],
              ),
              const Spacer(),
              Text(
                item.name,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (item.isPaper)
                // v0.3: the planned action is editable - tap to change it.
                InkWell(
                  onTap: onEditPaperAction,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            item.paperAction?.label ?? 'Paper',
                            style: theme.textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit_outlined, size: 12, color: theme.colorScheme.outline),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  '${item.quantity} x',
                  style: theme.textTheme.labelSmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon for a planned paper action (bottom sheet rows).
IconData _paperActionIcon(PaperAction action) => switch (action) {
      PaperAction.sort => Icons.sort,
      PaperAction.keep => Icons.bookmark_outline,
      PaperAction.file => Icons.drive_file_move_outline,
      PaperAction.recycle => Icons.delete_outline,
    };