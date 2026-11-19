import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../models/space.dart';
import '../state/app_state.dart';

/// Screen 4: one space, drag-and-drop item grid.
class SpaceDetailScreen extends StatelessWidget {
  const SpaceDetailScreen({super.key, required this.spaceId});

  final String spaceId;

  void _dropOnItem(AppState state, Item dragged, Item target) {
    if (dragged.id == target.id) return;
    if (dragged.spaceId == target.spaceId) {
      state.reorderItem(dragged.id, target.id);
    } else {
      state.moveItemToSpace(dragged.id, target.spaceId, beforeItemId: target.id);
    }
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
    final Space? space = state.spaceById(spaceId);

    if (space == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Space')),
        body: const Center(child: Text('This space no longer exists.')),
      );
    }

    final List<Item> spaceItems = state.items
        .where((Item item) => item.spaceId == spaceId)
        .toList()
      ..sort((Item a, Item b) => a.order.compareTo(b.order));

    final List<Space> otherSpaces = state.spaces
        .where((Space s) => s.id != spaceId)
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
                      '${state.looseInSpace(space.id)} loose',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Text('Tap = put away · Hold + drag = move', style: TextStyle(fontSize: 11)),
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
                                      Text(
                                        'Drop in ${target.name}',
                                        style: theme.textTheme.bodySmall,
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
                      child: Text(
                        'Nothing here yet.\nUse Quick add to log something.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
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
                          onToggle: () => state.toggleItemStatus(item),
                          onDelete: () => state.deleteItem(item.id),
                          onAccept: (Item dragged) => _dropOnItem(state, dragged, item),
                          onEditPaperAction: () => _editPaperAction(context, state, item),
                        );
                      },
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
    required this.onToggle,
    required this.onDelete,
    required this.onAccept,
    required this.onEditPaperAction,
  });

  final Item item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ValueChanged<Item> onAccept;
  final VoidCallback onEditPaperAction;

  @override
  Widget build(BuildContext context) {
    final Widget tile = _ItemTile(
      item: item,
      onToggle: onToggle,
      onDelete: onDelete,
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
            onToggle: () {},
            onDelete: () {},
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
    required this.onToggle,
    required this.onDelete,
    required this.onEditPaperAction,
  });

  final Item item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEditPaperAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool organized = item.status == ItemStatus.organized;

    return Material(
      color: organized ? theme.colorScheme.secondaryContainer : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
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
                  if (organized)
                    Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    constraints: const BoxConstraints(),
                    onSelected: (String value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (BuildContext context) =>
                        const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                    ],
                  ),
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
