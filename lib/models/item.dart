import 'package:flutter/foundation.dart';

/// Unified category: physical household objects or real paper piles.
enum ItemCategory { household, paper }

/// Loose = not put away yet, organized = it lives in its home now.
enum ItemStatus { loose, organized }

/// Planned action for a paper pile.
enum PaperAction { sort, keep, file, recycle }

extension ItemCategoryX on ItemCategory {
  String get label => switch (this) {
        ItemCategory.household => 'Household',
        ItemCategory.paper => 'Paper',
      };
}

extension PaperActionX on PaperAction {
  String get label => switch (this) {
        PaperAction.sort => 'Sort',
        PaperAction.keep => 'Keep',
        PaperAction.file => 'File',
        PaperAction.recycle => 'Recycle',
      };

  String get hint => switch (this) {
        PaperAction.sort => 'Split it into stay and go',
        PaperAction.keep => 'Keep it handy, out of the way',
        PaperAction.file => 'File it away in a labelled folder',
        PaperAction.recycle => 'Bin it and be done',
      };
}

@immutable
class Item {
  const Item({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.status,
    required this.spaceId,
    required this.order,
    required this.createdAt,
    this.paperAction,
  });

  final String id;
  final String name;
  final ItemCategory category;
  final int quantity;
  final ItemStatus status;
  final String spaceId;
  final PaperAction? paperAction;

  /// Sort index inside its space (used by the drag-and-drop grid).
  final int order;

  final DateTime createdAt;

  bool get isPaper => category == ItemCategory.paper;
  bool get isLoose => status == ItemStatus.loose;
  String get displayName => quantity > 1 ? '$name x$quantity' : name;

  Item copyWith({
    String? id,
    String? name,
    ItemCategory? category,
    int? quantity,
    ItemStatus? status,
    String? spaceId,
    PaperAction? paperAction,
    bool clearPaperAction = false,
    int? order,
    DateTime? createdAt,
  }) =>
      Item(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        status: status ?? this.status,
        spaceId: spaceId ?? this.spaceId,
        paperAction: clearPaperAction ? null : (paperAction ?? this.paperAction),
        order: order ?? this.order,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'category': category.name,
        'quantity': quantity,
        'status': status.name,
        'spaceId': spaceId,
        'paperAction': paperAction?.name,
        'order': order,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Item.fromMap(Map<String, dynamic> map) => Item(
        id: (map['id'] as String?) ?? '',
        name: (map['name'] as String?) ?? 'Item',
        category: ItemCategory.values.firstWhere(
          (ItemCategory c) => c.name == map['category'],
          orElse: () => ItemCategory.household,
        ),
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        status: ItemStatus.values.firstWhere(
          (ItemStatus s) => s.name == map['status'],
          orElse: () => ItemStatus.loose,
        ),
        spaceId: (map['spaceId'] as String?) ?? '',
        paperAction: map['paperAction'] == null
            ? null
            : PaperAction.values.firstWhere(
                (PaperAction a) => a.name == map['paperAction'],
                orElse: () => PaperAction.sort,
              ),
        order: (map['order'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num?)?.toInt() ?? 0),
      );
}
