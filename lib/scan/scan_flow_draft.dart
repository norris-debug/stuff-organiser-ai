part of 'scan_flow.dart';

// v0.8.17: the plan drafter lives in its own part file so every scan
// library file stays push- and verify-sized (the v0.8.11 split
// convention). The members moved here are part of the same library, so
// no other file changes.

extension _ScanDrafting on _ScanFlowScreenState {
  String _bucketSuggestion(int bucket, List<_RecognizedObject> items) {
    final String labels = _joinLabels(items);
    switch (bucket) {
      case 0:
        return _Suggestion(
          title: 'Give the $labels one pass: act, file or recycle',
          detail:
              'Paper only has three honest destinations. Hold each sheet and '
              'ask the three questions - anything that fails them goes out '
              'before any filing starts.',
          steps: <String>[
            'Gather every sheet into one pile on a clear spot.',
            'Split it into action, file and recycle.',
            'Recycle the third pile today, then file the keepers in one labelled folder.',
          ],
        );
      case 1:
        return _Suggestion(
          title: 'Fold the $labels into one stack',
          detail:
              'Folded and lined up, the same clothes take half the space and '
              'stop the pile from growing back.',
          steps: <String>[
            'Pull the items out and send anything worn-out straight to the donate pile.',
            'Fold each keeper and line the stack up in wear order.',
            'Give the stack one fixed home - a shelf or a drawer, not a chair.',
          ],
        );
      case 2:
        return _Suggestion(
          title: 'Wash and home the $labels in one batch',
          detail:
              'One batch beats sorting dirty from clean, and everything gets '
              'one shelf it always returns to.',
          steps: <String>[
            'Collect the items into one group by the sink.',
            'Wash them in a single batch and dry them together.',
            'Home them in one spot, everyday pieces at the front.',
          ],
        );
      case 3:
        return _Suggestion(
          title: 'Coil the $labels into one labelled box',
          detail:
              'Tangled cables eat surface space and vanish when needed. One '
              'box, one label, one drawer.',
          steps: <String>[
            'Untangle everything and set aside what no longer works.',
            'Coil each keeper and band it.',
            'Box them, label the front, and give the box one drawer.',
          ],
        );
      case 4:
        return _Suggestion(
          title: 'Sort the $labels down to the keepers',
          detail:
              'Containers multiply quietly. Keep the ones you actually use '
              'and let the rest go without guilt.',
          steps: <String>[
            'Empty each one and match lids to bodies.',
            'Keep the pairs that get used; donate or bin the rest.',
            'Nest the keepers and store them near where they are used.',
          ],
        );
      case 5:
        return _Suggestion(
          title: 'Shelve the $labels upright in one row',
          detail:
              'Upright books use height instead of depth and you can see '
              'every title at a glance.',
          steps: <String>[
            'Take them all down and let go of the ones you will not read again.',
            'Shelve the keepers upright, tallest at the side.',
            'Leave a little space at the end so the row can breathe.',
          ],
        );
      case 6:
        return _Suggestion(
          title: 'Give the $labels one home',
          detail:
              'Toys without a home always end up back on the floor. One box '
              'per kind fixes it.',
          steps: <String>[
            'Gather them and set aside anything broken.',
            'Sort the keepers by kind into one box each.',
            'Put the boxes on one low shelf you can reach.',
          ],
        );
      default:
        return _Suggestion(
          title: 'Give the $labels one home',
          detail:
              'Hold each one and ask: do I need it, use it, love it? Whatever '
              'fails all three has served its purpose - let it go.',
          steps: <String>[
            'Group the items by where they belong.',
            'Donate or bin the ones that fail the three questions.',
            'Give every keeper a fixed home, one touch away.',
          ],
        );
    }
  }

  /// Builds the coach plan from the recognized object list. Observations
  /// name the actual items with tier-honest wording, suggestions come from
  /// the biggest work buckets, and the Danshari opener leads.
  _ScanPlan _recognitionPlan(List<_RecognizedObject> items, String notes) {
    final List<_RecognizedObject> confirmed = <_RecognizedObject>[];
    final List<_RecognizedObject> verify = <_RecognizedObject>[];
    final List<_RecognizedObject> flagged = <_RecognizedObject>[];
    for (final _RecognizedObject item in items) {
      if (item.tier == 0) {
        confirmed.add(item);
      } else if (item.tier == 2) {
        flagged.add(item);
      } else {
        verify.add(item);
      }
    }
    final int total = items.length;
    final List<String> observations = <String>[
      'Before anything else, for each item ask: do I need, use and love '
          'this right now. Whatever fails all three goes to the donate or bin '
          'pile before any organising starts.',
    ];
    if (confirmed.isNotEmpty) {
      observations
          .add('Straight from your scan, I can see: ${_joinLabels(confirmed)}.');
      final int pick = total % 3;
      if (pick == 0) {
        observations.add(
            'Each of those is sitting out with no fixed home yet - that is '
            'the first thing to fix.');
      } else if (pick == 1) {
        observations.add(
            'They are visible clutter right now, which is good news: visible '
            'means sortable in one session.');
      } else {
        observations.add(
            'None of those needs a purchase or a project - just decisions '
            'and one home each.');
      }
    }
    if (verify.isNotEmpty) {
      observations.add(
          'I think I can also see ${_joinLabels(verify)} - double-check '
          'those for me before we plan around them.');
    }
    if (flagged.isNotEmpty) {
      observations.add(
          'A few reads were too unsure to act on: ${_joinLabels(flagged)}. '
          'Tell me what they actually are and I will fold them in.');
    }
    if (notes.trim().isNotEmpty) {
      observations.add(
          'Your notes are in: the plan below also covers the things you '
          'described that the photos cannot show.');
    }
    final Map<int, List<_RecognizedObject>> buckets =
        <int, List<_RecognizedObject>>{};
    for (final _RecognizedObject item in items) {
      final int bucket = _bucketOf(item.label);
      buckets.putIfAbsent(bucket, () => <_RecognizedObject>[]).add(item);
    }
    final List<int> order = buckets.keys.toList();
    order.sort((int a, int b) => buckets[b]!.length.compareTo(buckets[a]!.length));
    final List<_Suggestion> suggestions = <_Suggestion>[];
    final int wanted = total <= 3 ? 2 : 3;
    for (final int bucket in order) {
      if (suggestions.length >= wanted) break;
      suggestions.add(_bucketSuggestion(bucket, buckets[bucket]!));
    }
    if (suggestions.isEmpty) {
      suggestions.add(_bucketSuggestion(7, items));
    }
    if (suggestions.length == 1) {
      suggestions.add(const _Suggestion(
        title: 'Clear one surface down to zero',
        detail:
            'Pick one flat surface and leave it completely empty. A clear '
            'surface is the fastest reset a room has.',
        steps: <String>[
          'Sweep everything off it into one pile.',
          'Sort the pile: home, relocate or donate.',
          'Wipe it down and keep only what truly lives there.',
        ],
      ));
    }
    return _ScanPlan(
      observations: observations,
      suggestions:
          suggestions.length > 4 ? suggestions.sublist(0, 4) : suggestions,
      habits: const <String>[
        'One in, one out - a new item replaces an old one.',
        'Keep everyday things one touch away from where they are used.',
        'Clear the surface before you leave the room.',
      ],
      tidiness: total <= 2 ? 'tidy' : (total <= 8 ? 'moderate' : 'messy'),
    );
  }
}
