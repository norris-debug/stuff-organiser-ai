import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/item.dart';
import '../models/space.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/plan_engine.dart';
import '../theme/app_theme.dart';

/// Application state shared across the widget tree.
///
/// Owns the signed-in user, the spaces and items of the current account and the
/// locally persisted preferences (theme pack, mascot, onboarding flag).
class AppState extends ChangeNotifier {
  AppState({
    required this.authService,
    required this.dataService,
    required this.prefs,
  });

  final AuthService authService;
  final DataService dataService;
  final SharedPreferences prefs;

  static const String _kThemePack = 'theme_pack_id';
  static const String _kMascot = 'mascot_variant';
  static const String _kOnboarded = 'onboarding_complete';

  AppUser? user;
  List<Space> spaces = <Space>[];
  List<Item> items = <Item>[];
  ThemePack themePack = themePacks.first;
  MascotVariant mascot = MascotVariant.bunny;
  bool onboardingComplete = false;
  bool loading = true;
  String? errorMessage;

  /// Bumped whenever an item becomes organized so the mascot can celebrate.
  int celebrationTick = 0;

  int _idCounter = 0;

  bool get demoMode => authService.isDemo;
  String get uid => user?.uid ?? 'demo-local-user';
  int get looseCount => items.where((Item item) => item.status == ItemStatus.loose).length;
  int get organizedCount => items.where((Item item) => item.status == ItemStatus.organized).length;
  TidyPlan get currentPlan => PlanEngine.buildPlan(spaces: spaces, items: items);

  /// Normalises an item name for duplicate detection.
  ///
  /// Trims the outer whitespace, lowercases the text and collapses runs of
  /// internal whitespace into a single space.
  static String normalizeItemName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Loads the persisted preferences and the account data.
  Future<void> bootstrap() async {
    themePack = themePackById(prefs.getString(_kThemePack) ?? themePacks.first.id);
    final String? mascotName = prefs.getString(_kMascot);
    mascot = MascotVariant.values.firstWhere(
      (MascotVariant variant) => variant.name == mascotName,
      orElse: () => themePack.mascots.first,
    );
    onboardingComplete = prefs.getBool(_kOnboarded) ?? false;

    user = await authService.currentUser();
    user ??= await authService.signInAnonymously();

    await _reload();
    loading = false;
    notifyListeners();
  }

  /// Reloads spaces and items for the current user.
  Future<void> _reload() async {
    final String id = uid;
    spaces = await dataService.loadSpaces(id);
    items = await dataService.loadItems(id);
  }

  /// Generates a unique id with the given [prefix].
  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  /// The space with the given [id], or `null` when it no longer exists.
  Space? spaceById(String id) {
    for (final Space space in spaces) {
      if (space.id == id) return space;
    }
    return null;
  }

  /// The item with the given [id], or `null` when it no longer exists.
  Item? itemById(String id) {
    for (final Item item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Number of items stored in a space.
  int countInSpace(String spaceId) =>
      items.where((Item item) => item.spaceId == spaceId).length;

  /// Number of still loose items stored in a space.
  int looseInSpace(String spaceId) => items
      .where((Item item) => item.spaceId == spaceId && item.status == ItemStatus.loose)
      .length;

  /// Items of a space ordered by their persisted order value.
  List<Item> itemsInSpace(String spaceId) {
    final List<Item> list = items.where((Item item) => item.spaceId == spaceId).toList();
    list.sort((Item a, Item b) => a.order.compareTo(b.order));
    return list;
  }

  /// Rule-based suggestion of the space for a new item.
  String? suggestSpaceId(String name, ItemCategory category) {
    final Map<String, int> counts = <String, int>{
      for (final Space space in spaces) space.id: countInSpace(space.id),
    };
    return PlanEngine.suggestSpace(name, category, spaces, itemCounts: counts)?.id;
  }

  /// Creates a space and persists it.
  Future<Space> addSpace(String name, {String emoji = '📦'}) async {
    final Space space = Space(
      id: _newId('space'),
      name: name.trim().isEmpty ? 'New space' : name.trim(),
      emoji: emoji,
      createdAt: DateTime.now(),
    );
    spaces = <Space>[...spaces, space];
    notifyListeners();
    await dataService.saveSpace(uid, space);
    return space;
  }

  /// Renames a space and persists it.
  Future<void> renameSpace(String id, String name) async {
    final Space? space = spaceById(id);
    if (space == null) return;
    final Space updated = space.copyWith(name: name.trim());
    spaces = spaces
        .map((Space s) => s.id == id ? updated : s)
        .toList();
    notifyListeners();
    await dataService.saveSpace(uid, updated);
  }

  /// Deletes a space together with its items.
  Future<void> deleteSpace(String id) async {
    spaces = spaces.where((Space s) => s.id != id).toList();
    items = items.where((Item i) => i.spaceId != id).toList();
    notifyListeners();
    await dataService.deleteSpace(uid, id);
  }

  /// Adds an item and persists it.
  ///
  /// The quantity is clamped to at least one and paper items always receive a
  /// planned action.
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

  /// Finds an existing item in [spaceId] whose normalised name matches [name].
  ///
  /// Returns `null` when nothing matches so callers can offer a merge instead
  /// of silently creating a second, identical entry.
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

  Future<void> setThemePack(ThemePack pack) async {
    themePack = pack;
    if (!pack.mascots.contains(mascot)) {
      mascot = pack.mascots.first;
      await prefs.setString(_kMascot, mascot.name);
    }
    await prefs.setString(_kThemePack, pack.id);
    notifyListeners();
  }

  Future<void> setMascot(MascotVariant variant) async {
    mascot = variant;
    await prefs.setString(_kMascot, variant.name);
    notifyListeners();
  }

  Future<void> completeOnboarding(String spaceName, {String emoji = '📦'}) async {
    await addSpace(spaceName, emoji: emoji);
    onboardingComplete = true;
    await prefs.setBool(_kOnboarded, true);
    notifyListeners();
  }

  Future<void> replayOnboarding() async {
    onboardingComplete = false;
    await prefs.setBool(_kOnboarded, false);
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    errorMessage = null;
    try {
      user = await authService.signIn(email: email, password: password);
      await _reload();
    } catch (error) {
      errorMessage = _friendlyError(error);
    }
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    errorMessage = null;
    try {
      user = await authService.signUp(email: email, password: password);
      await _reload();
    } catch (error) {
      errorMessage = _friendlyError(error);
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await authService.signOut();
    user = null;
    errorMessage = null;
    await _reload();
    notifyListeners();
  }

  Future<void> resetDemoData() async {
    await dataService.clearDemoData();
    await _reload();
    notifyListeners();
  }

  String _friendlyError(Object error) {
    final String text = error.toString();
    if (text.contains('invalid-email')) return 'That email does not look right.';
    if (text.contains('wrong-password') || text.contains('invalid-credential')) {
      return 'Wrong email or password.';
    }
    if (text.contains('email-already-in-use')) return 'That email is already registered.';
    if (text.contains('network')) return 'No connection. Check your network and try again.';
    return 'Something went wrong. Try again.';
  }
}
