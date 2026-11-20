import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/item.dart';
import '../models/space.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/plan_engine.dart';
import '../theme/app_theme.dart';

part 'app_state_items.dart';

/// Application state shared across the widget tree.
///
/// Owns the signed-in user, the spaces and items of the current account and
/// the locally persisted preferences (theme pack, mascot, onboarding flag).
/// The item mutations live in app_state_items.dart (part file, same
/// library) to keep every file push- and verify-sized.
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
  ///
  /// v0.8.16 (Meiosis TC-06): whitespace-only names can never replace a
  /// real space name - the guard lives in the state layer, not just the
  /// dialog, so every future caller inherits it.
  Future<void> renameSpace(String id, String name) async {
    final Space? space = spaceById(id);
    if (space == null) return;
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final Space updated = space.copyWith(name: trimmed);
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
    // v0.8.16 (Meiosis TC-02): a rapid double-tap on "Start organising"
    // must not run completion twice; this backstop sits behind the UI
    // guard in onboarding_screen.dart.
    if (onboardingComplete) return;
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