import '../models/item.dart';
import '../models/space.dart';

/// A quick-add chip. One tap fills the name + category (second tap = Add).
class QuickAddPreset {
  const QuickAddPreset({
    required this.id,
    required this.label,
    required this.emoji,
    required this.category,
    this.paperAction,
  });

  final String id;
  final String label;
  final String emoji;
  final ItemCategory category;
  final PaperAction? paperAction;
}

/// One checklist step of a sprint.
class PlanStep {
  const PlanStep({
    required this.itemId,
    required this.title,
    required this.detail,
    required this.seconds,
    required this.spaceId,
  });

  final String itemId;
  final String title;
  final String detail;
  final int seconds;
  final String spaceId;
}

/// A 10-minute sprint dedicated to one zone.
class PlanSprint {
  const PlanSprint({
    required this.id,
    required this.spaceId,
    required this.spaceName,
    required this.spaceEmoji,
    required this.minutes,
    required this.steps,
  });

  final String id;
  final String spaceId;
  final String spaceName;
  final String spaceEmoji;

  /// Budget of the sprint (10 minutes).
  final int minutes;

  final List<PlanStep> steps;

  int get totalSeconds => steps.fold<int>(0, (int sum, PlanStep step) => sum + step.seconds);

  String get estimateLabel {
    if (totalSeconds <= 0) return '~0 min';
    if (totalSeconds < 60) return '~$totalSeconds sec';
    return '~${(totalSeconds / 60).ceil()} min';
  }
}

/// The whole start plan: top zones as sprints.
class TidyPlan {
  const TidyPlan({required this.sprints});

  final List<PlanSprint> sprints;

  bool get isEmpty => sprints.isEmpty;
  int get totalItems => sprints.fold<int>(0, (int sum, PlanSprint sprint) => sum + sprint.steps.length);
  int get totalSeconds => sprints.fold<int>(0, (int sum, PlanSprint sprint) => sum + sprint.totalSeconds);
  int get totalMinutes => (totalSeconds / 60).ceil();
}

/// Rule-based "AI": decides where an item lives and how to start tidying.
class PlanEngine {
  const PlanEngine._();

  static const int sprintMinutes = 10;
  static const int maxSprints = 3;
  static const int householdStepSeconds = 30;
  static const int paperStepSeconds = 45;

  /// Keywords per canonical zone.
  static const Map<String, List<String>> spaceKeywords = <String, List<String>>{
    'kitchen': <String>[
      'cup', 'mug', 'glass', 'plate', 'dish', 'bowl', 'cutlery', 'fork', 'knife', 'spoon',
      'pan', 'pot', 'kettle', 'bottle', 'jar', 'tin', 'can', 'coffee', 'tea', 'fridge',
      'microwave', 'toaster', 'lunch box',
    ],
    'desk': <String>[
      'paper', 'document', 'invoice', 'receipt', 'letter', 'mail', 'note', 'notebook',
      'folder', 'bill', 'assignment', 'homework', 'study', 'book', 'post', 'card',
    ],
    'wardrobe': <String>[
      'clothes', 'clothing', 'shirt', 'tshirt', 't-shirt', 'trousers', 'pants', 'sock',
      'jacket', 'dress', 'skirt', 'jeans', 'hoodie', 'sweater', 'shoe', 'coat',
      'underwear', 'pyjamas',
    ],
    'bathroom': <String>[
      'towel', 'toothbrush', 'toothpaste', 'shampoo', 'soap', 'comb', 'makeup', 'cream',
    ],
    'living room': <String>[
      'cushion', 'blanket', 'remote', 'magazine', 'board game', 'puzzle',
    ],
    'bedroom': <String>['pillow', 'duvet', 'sheet', 'bedside'],
    'laundry': <String>['laundry', 'washing', 'iron', 'hanger'],
    'garage': <String>['tool', 'screw', 'cord', 'garden'],
    'study': <String>[
      'paper', 'notes', 'textbook', 'revision', 'exam', 'assignment', 'folder', 'book',
    ],
    'office': <String>['paper', 'invoice', 'contract', 'folder', 'report'],
  };

  /// Multi word zones first so "living room" wins over "room"-like names.
  static const List<String> _canonicalOrder = <String>[
    'living room', 'kitchen', 'wardrobe', 'bathroom', 'bedroom',
    'laundry', 'garage', 'study', 'office', 'desk',
  ];

  static const List<QuickAddPreset> presets = <QuickAddPreset>[
    QuickAddPreset(id: 'cup', label: 'Cup', emoji: '🥤', category: ItemCategory.household),
    QuickAddPreset(id: 'dish', label: 'Dish', emoji: '🍽️', category: ItemCategory.household),
    QuickAddPreset(id: 'clothes', label: 'Clothes', emoji: '👕', category: ItemCategory.household),
    QuickAddPreset(id: 'trousers', label: 'Trousers', emoji: '👖', category: ItemCategory.household),
    QuickAddPreset(
      id: 'paper',
      label: 'Paper pile',
      emoji: '📄',
      category: ItemCategory.paper,
      paperAction: PaperAction.sort,
    ),
  ];

  static String? _canonicalKey(String spaceName) {
    for (final String key in _canonicalOrder) {
      if (spaceName.contains(key)) return key;
    }
    return null;
  }

  static int _scoreSpace(Space space, String itemName, ItemCategory category) {
    final String spaceName = space.name.trim().toLowerCase();
    final String? canonical = _canonicalKey(spaceName);
    int score = 0;

    final List<String> keywords =
        canonical == null ? const <String>[] : spaceKeywords[canonical] ?? const <String>[];
    int hits = 0;
    for (final String keyword in keywords) {
      if (itemName.contains(keyword)) {
        hits++;
        if (hits >= 2) break;
      }
    }
    score += hits * 2;

    // The space is named after the item (e.g. space "Cupboard", item "cup").
    if (spaceName.length > 2) {
      if (itemName.contains(spaceName)) {
        score += 3;
      } else {
        for (final String word in itemName.split(' ')) {
          if (word.length > 2 && spaceName.contains(word)) {
            score += 2;
            break;
          }
        }
      }
    }

    // Paper piles belong near the desk / study / office zone.
    if (category == ItemCategory.paper &&
        (canonical == 'desk' || canonical == 'study' || canonical == 'office')) {
      score += 1;
    }
    return score;
  }

  /// Suggests where an item belongs. Falls back to the emptiest space.
  static Space? suggestSpace(
    String itemName,
    ItemCategory category,
    List<Space> spaces, {
    Map<String, int> itemCounts = const <String, int>{},
  }) {
    if (spaces.isEmpty) return null;
    final String lower = itemName.trim().toLowerCase();

    Space? best;
    int bestScore = 0;
    for (final Space space in spaces) {
      final int score = _scoreSpace(space, lower, category);
      if (score > bestScore) {
        bestScore = score;
        best = space;
      }
    }
    if (best != null) return best;

    Space? emptiest;
    int lowest = 1 << 30;
    for (final Space space in spaces) {
      final int count = itemCounts[space.id] ?? 0;
      if (count < lowest) {
        lowest = count;
        emptiest = space;
      }
    }
    return emptiest ?? spaces.first;
  }

  /// Builds the start plan: the top [maxSprints] zones (most loose items)
  /// turned into 10-minute sprints with per-sprint time estimates.
  static TidyPlan buildPlan({required List<Space> spaces, required List<Item> items}) {
    final List<Item> loose = items.where((Item item) => item.status == ItemStatus.loose).toList()
      ..sort((Item a, Item b) => a.order.compareTo(b.order));

    final Map<String, List<Item>> grouped = <String, List<Item>>{};
    for (final Item item in loose) {
      grouped.putIfAbsent(item.spaceId, () => <Item>[]).add(item);
    }

    final List<MapEntry<String, List<Item>>> ranked = grouped.entries.toList()
      ..sort((MapEntry<String, List<Item>> a, MapEntry<String, List<Item>> b) {
        final int diff = b.value.length.compareTo(a.value.length);
        return diff != 0 ? diff : a.key.compareTo(b.key);
      });

    final List<PlanSprint> sprints = <PlanSprint>[];
    for (final MapEntry<String, List<Item>> entry in ranked.take(maxSprints)) {
      Space? space;
      for (final Space candidate in spaces) {
        if (candidate.id == entry.key) {
          space = candidate;
          break;
        }
      }
      final String spaceName = space?.name ?? 'Unassigned';
      final String spaceEmoji = space?.emoji ?? '🧺';

      final List<PlanStep> steps = entry.value.map((Item item) {
        final bool paper = item.isPaper;
        return PlanStep(
          itemId: item.id,
          title: paper
              ? '${item.paperAction?.label ?? 'Sort'} the paper pile'
              : 'Put away ${item.displayName}',
          detail: paper ? (item.paperAction?.hint ?? '') : 'Home: $spaceName',
          seconds: paper ? paperStepSeconds : householdStepSeconds,
          spaceId: entry.key,
        );
      }).toList();

      sprints.add(PlanSprint(
        id: 'sprint-${entry.key}',
        spaceId: entry.key,
        spaceName: spaceName,
        spaceEmoji: spaceEmoji,
        minutes: sprintMinutes,
        steps: steps,
      ));
    }
    return TidyPlan(sprints: sprints);
  }
}
