import 'package:flutter/foundation.dart';

/// A zone of the house: kitchen, desk, wardrobe, ...
@immutable
class Space {
  const Space({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String emoji;
  final DateTime createdAt;

  Space copyWith({String? id, String? name, String? emoji, DateTime? createdAt}) => Space(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'emoji': emoji,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Space.fromMap(Map<String, dynamic> map) => Space(
        id: (map['id'] as String?) ?? '',
        name: (map['name'] as String?) ?? 'Space',
        emoji: (map['emoji'] as String?) ?? '📦',
        createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num?)?.toInt() ?? 0),
      );
}
