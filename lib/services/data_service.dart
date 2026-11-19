import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';
import '../models/space.dart';

/// Firestore wrapper. Without a [db] instance it falls back to an in-memory
/// store seeded with mock data so the app runs without credentials.
class DataService {
  DataService({FirebaseFirestore? db}) : _db = db;

  final FirebaseFirestore? _db;

  final Map<String, Space> _memSpaces = <String, Space>{};
  final Map<String, Item> _memItems = <String, Item>{};
  bool _seeded = false;

  bool get isDemo => _db == null;

  CollectionReference<Map<String, dynamic>> _spaces(String uid) =>
      _db!.collection('users').doc(uid).collection('spaces');

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _db!.collection('users').doc(uid).collection('items');

  Future<List<Space>> loadSpaces(String uid) async {
    if (isDemo) {
      _seedDemo();
      final List<Space> list = _memSpaces.values.toList()
        ..sort((Space a, Space b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _spaces(uid).get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            Space.fromMap(<String, dynamic>{...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<Item>> loadItems(String uid) async {
    if (isDemo) {
      _seedDemo();
      return _memItems.values.toList();
    }
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _items(uid).get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            Item.fromMap(<String, dynamic>{...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> saveSpace(String uid, Space space) async {
    if (isDemo) {
      _memSpaces[space.id] = space;
      return;
    }
    await _spaces(uid).doc(space.id).set(space.toMap());
  }

  Future<void> deleteSpace(String uid, String spaceId) async {
    if (isDemo) {
      _memSpaces.remove(spaceId);
      _memItems.removeWhere((String key, Item item) => item.spaceId == spaceId);
      return;
    }
    final QuerySnapshot<Map<String, dynamic>> items =
        await _items(uid).where('spaceId', isEqualTo: spaceId).get();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in items.docs) {
      await doc.reference.delete();
    }
    await _spaces(uid).doc(spaceId).delete();
  }

  Future<void> saveItem(String uid, Item item) async {
    if (isDemo) {
      _memItems[item.id] = item;
      return;
    }
    await _items(uid).doc(item.id).set(item.toMap());
  }

  Future<void> deleteItem(String uid, String itemId) async {
    if (isDemo) {
      _memItems.remove(itemId);
      return;
    }
    await _items(uid).doc(itemId).delete();
  }

  /// Clears the demo store so the next read re-seeds the mock data.
  Future<void> clearDemoData() async {
    if (!isDemo) return;
    _memSpaces.clear();
    _memItems.clear();
    _seeded = false;
  }

  void _seedDemo() {
    if (_seeded) return;
    _seeded = true;
    final DateTime now = DateTime.now();

    final Space kitchen = Space(id: 'demo-space-kitchen', name: 'Kitchen', emoji: '🍳', createdAt: now);
    final Space desk = Space(id: 'demo-space-desk', name: 'Desk', emoji: '🗂️', createdAt: now);
    final Space wardrobe = Space(id: 'demo-space-wardrobe', name: 'Wardrobe', emoji: '👕', createdAt: now);
    _memSpaces.addAll(<String, Space>{
      kitchen.id: kitchen,
      desk.id: desk,
      wardrobe.id: wardrobe,
    });

    _memItems.addAll(<String, Item>{
      'demo-item-1': Item(
        id: 'demo-item-1',
        name: 'Mug',
        category: ItemCategory.household,
        quantity: 2,
        status: ItemStatus.loose,
        spaceId: kitchen.id,
        order: 0,
        createdAt: now,
      ),
      'demo-item-2': Item(
        id: 'demo-item-2',
        name: 'Dinner plate',
        category: ItemCategory.household,
        quantity: 3,
        status: ItemStatus.loose,
        spaceId: kitchen.id,
        order: 1,
        createdAt: now,
      ),
      'demo-item-3': Item(
        id: 'demo-item-3',
        name: 'Paper pile',
        category: ItemCategory.paper,
        quantity: 1,
        status: ItemStatus.loose,
        spaceId: desk.id,
        order: 0,
        paperAction: PaperAction.sort,
        createdAt: now,
      ),
      'demo-item-4': Item(
        id: 'demo-item-4',
        name: 'Socks',
        category: ItemCategory.household,
        quantity: 4,
        status: ItemStatus.organized,
        spaceId: wardrobe.id,
        order: 0,
        createdAt: now,
      ),
    });
  }
}
