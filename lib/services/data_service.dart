import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';
import '../models/space.dart';

/// Firestore wrapper. Without a [db] instance it falls back to an in-memory
/// store so the app runs without credentials.
///
/// v0.8.16: first-time users start with an empty home - "Your spaces" and
/// Today's plan fill up only from real scans and quick-adds (Herrick's
/// redesign directive). The old demo seed (kitchen mugs and dinner plates,
/// desk paper pile, wardrobe socks) is gone, so "Reset demo data" now
/// clears to this same empty state.
class DataService {
  DataService({FirebaseFirestore? db}) : _db = db;

  final FirebaseFirestore? _db;

  final Map<String, Space> _memSpaces = <String, Space>{};
  final Map<String, Item> _memItems = <String, Item>{};

  bool get isDemo => _db == null;

  CollectionReference<Map<String, dynamic>> _spaces(String uid) =>
      _db!.collection('users').doc(uid).collection('spaces');

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _db!.collection('users').doc(uid).collection('items');

  Future<List<Space>> loadSpaces(String uid) async {
    if (isDemo) {
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

  /// Clears the demo store so the next read starts from an empty home.
  Future<void> clearDemoData() async {
    if (!isDemo) return;
    _memSpaces.clear();
    _memItems.clear();
  }
}