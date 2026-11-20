part of 'app_state.dart';

/// The item mutations of AppState, split into a part file so every file
/// stays push- and verify-sized. Behavior is unchanged except where noted.
extension _AppStateItemOps on AppState {
  /// Adds an item and persists it.
  ///
  /// The quantity is clamped to at least one and paper items always receive
  /// a planned action.
  Future<Item> addItem({
    required String name,
    required ItemCategory category,
    int quantity = 1,
    String? spaceId,
    PaperAction? paperAction,
  }) async {
    final String trimmed = name.trim();
    final String? resolvedSpaceId = spaceId ?? suggestSpaceId(trimmed, category);
    final int order = _nextOrderInSpace(resolvedSpaceId ?? '');

    final Item item = Item(
      id: _newId('item'),
      name: trimmed.isEmpty ? 'Item' : trimmed,
      category: category,
      quantity: quantity < 1 ? 1 : quantity,
      status: ItemStatus.loose,
      spaceId: resolvedSpaceId ?? '',
      order: order,
      createdAt: DateTime.now(),
      paperAction: category == ItemCategory.paper ? (paperAction ?? PaperAction.sort) : null,
    );

    items = <Item>[...items, item];
    notifyListeners();
    await dataService.saveItem(uid, item);
    return item;
  }

  /// Next free order value inside [spaceId].
  ///
  /// Uses the highest stored order plus one so a gap left by a cross-space
  /// move can never make two items share an order value.
  int _nextOrderInSpace(String spaceId) {
    int next = 0;
    for (final Item item in items) {
      if (item.spaceId != spaceId) continue;
      if (item.order + 1 > next) next = item.order + 1;
    }
    return next;
  }

  /// Finds an existing item in [spaceId] whose normalised name matches
  /// [name]. Returns `null` when nothing matches so callers can offer a
  /// merge instead of silently creating a second, identical entry.
  Item? findDuplicate(String name, String? spaceId) {
    final String normalized = normalizeItemName(name);
    if (normalized.isEmpty) return null;
    final String targetSpaceId = spaceId ?? '';
    for (final Item item in items) {
      if (item.spaceId != targetSpaceId) continue;
      if (normalizeItemName(item.name) == normalized) return item;
    }
    return null;
  }

  /// Increases the quantity of [existing] by [addQuantity] and persists it.
  ///
  /// Used by the quick-add duplicate guard to fold a would-be duplicate into
  /// the entry that is already stored in the target space.
  Future<Item?> mergeIntoItem(Item existing, int addQuantity) async {
    final Item? current = itemById(existing.id);
    if (current == null) return null;
    final int delta = addQuantity < 1 ? 1 : addQuantity;
    final Item updated = current.copyWith(quantity: current.quantity + delta);
    items = items.map((Item i) => i.id == updated.id ? updated : i).toList();
    notifyListeners();
    await dataService.saveItem(uid, updated);
    return updated;
  }

  /// Changes the planned paper action of a paper item and persists it.
  Future<void> setPaperAction(String itemId, PaperAction action) async {
    final Item? item = itemById(itemId);
    if (item == null || !item.isPaper) return;
    if (item.paperAction == action) return;
    final Item updated = item.copyWith(paperAction: action);
    items = items.map((Item i) => i.id == updated.id ? updated : i).toList();
    notifyListeners();
    await dataService.saveItem(uid, updated);
  }

  /// Flips an item between loose and organized.
  Future<void> toggleItemStatus(Item item) async {
    final ItemStatus next =
        item.status == ItemStatus.loose ? ItemStatus.organized : ItemStatus.loose;
    final Item updated = item.copyWith(status: next);
    items = items.map((Item i) => i.id == updated.id ? updated : i).toList();
    if (next == ItemStatus.organized) {
      celebrationTick++;
    }
    notifyListeners();
    await dataService.saveItem(uid, updated);
  }

  /// Deletes an item.
  Future<void> deleteItem(String id) async {
    items = items.where((Item i) => i.id != id).toList();
    notifyListeners();
    await dataService.deleteItem(uid, id);
  }

  /// Reorders an item inside its own space (drop onto another item).
  ///
  /// Returns without touching storage when the item, the target or the space
  /// no longer exist, or when the resulting order is identical to the stored
  /// one.
  Future<void> reorderItem(String itemId, String targetItemId) async {
    final Item? dragged = itemById(itemId);
    final Item? target = itemById(targetItemId);
    if (dragged == null || target == null) return;
    if (dragged.id == target.id || dragged.spaceId != target.spaceId) return;
    if (!_spaceExists(dragged.spaceId)) return;

    final List<Item> list = items.where((Item i) => i.spaceId == target.spaceId).toList()
      ..sort((Item a, Item b) => a.order.compareTo(b.order));
    list.removeWhere((Item i) => i.id == itemId);
    final int index = list.indexWhere((Item i) => i.id == targetItemId);
    list.insert(index < 0 ? list.length : index, dragged);
    await _applyOrder(list);
  }

  /// Moves an item to another space, optionally in front of [beforeItemId].
  ///
  /// The target space has to exist (it may have been deleted while a drag was
  /// in progress). Nothing is written when the resulting order is unchanged.
  Future<void> moveItemToSpace(String itemId, String spaceId, {String? beforeItemId}) async {
    final Item? item = itemById(itemId);
    if (item == null) return;
    if (spaceId.isEmpty || spaceById(spaceId) == null) return;

    final List<Item> target = items
        .where((Item i) => i.spaceId == spaceId && i.id != itemId)
        .toList()
      ..sort((Item a, Item b) => a.order.compareTo(b.order));

    int index = target.length;
    if (beforeItemId != null) {
      final int found = target.indexWhere((Item i) => i.id == beforeItemId);
      if (found >= 0) index = found;
    }
    target.insert(index, item.copyWith(spaceId: spaceId));
    await _applyOrder(target);
  }

  /// Whether [spaceId] still points at an existing space.
  ///
  /// The empty id is used for unfiled items and is therefore always valid.
  bool _spaceExists(String spaceId) {
    if (spaceId.isEmpty) return true;
    return spaceById(spaceId) != null;
  }

  /// Persists the given ordering of items.
  ///
  /// The list is renumbered from zero upwards. When neither the order values
  /// nor the space of any item change, nothing is written and no listener is
  /// notified.
  Future<void> _applyOrder(List<Item> list) async {
    final List<Item> updated = <Item>[];
    for (int i = 0; i < list.length; i++) {
      updated.add(list[i].copyWith(order: i));
    }

    final Map<String, Item> currentById = <String, Item>{
      for (final Item item in items) item.id: item,
    };
    final bool changed = updated.any((Item candidate) {
      final Item? current = currentById[candidate.id];
      if (current == null) return true;
      // Compare order AND space: a cross-space move that lands on the same
      // numeric index must still be persisted.
      return current.order != candidate.order || current.spaceId != candidate.spaceId;
    });
    if (!changed) return;

    final Map<String, Item> byId = <String, Item>{
      for (final Item item in updated) item.id: item,
    };
    items = items.map((Item i) => byId[i.id] ?? i).toList();
    notifyListeners();
    for (final Item item in updated) {
      await dataService.saveItem(uid, item);
    }
  }
}