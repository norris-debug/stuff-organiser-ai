part of 'scan_flow.dart';

const List<_DemoBank> _demoBanks = <_DemoBank>[
  _DemoBank(
    observations: <String>[
      'Loose papers are covering the flat surface with no home yet.',
      'Folders and notebooks are stacked at odd angles.',
      'A few documents look like they still need an action.',
    ],
    suggestions: <_Suggestion>[
      _Suggestion(
        title: 'Sort the paper piles into action, file and recycle',
        detail:
            'Spread the loose sheets out and split them into three piles so '
            'nothing stays on the surface.',
        steps: <String>[
          'Gather every loose sheet into one pile on the clear part of the surface.',
          'Split that pile into three: action, file and recycle.',
          'Recycle the third pile, file the second in one labelled folder, and act on the first.',
        ],
      ),
      _Suggestion(
        title: 'File the loose documents in one labelled folder',
        detail:
            'Everything worth keeping goes into a single folder with a written '
            'label so it can be found in seconds.',
        steps: <String>[
          'Line the keepers up in date order.',
          'Slide them into one clear folder and write the label on the front.',
          'Stand the folder upright with the papers you use most in front of it.',
        ],
      ),
      _Suggestion(
        title: 'Stand the folders upright in a single row',
        detail:
            'Upright folders use the height of the shelf instead of its '
            'width and stop the pile from spreading again.',
        steps: <String>[
          'Collect every folder into one group.',
          'Stand them upright in a single row, biggest at the back.',
          'Keep only the folder in use at the front of the row.',
        ],
      ),
      _Suggestion(
        title: 'Clear the surface down to one working tray',
        detail:
            'A single tray gives every remaining sheet of paper a fixed home.',
        steps: <String>[
          'Take one small tray or shallow box.',
          'Drop the papers you touch daily into the tray.',
          'Store the tray at hand height and clear everything else off the surface.',
        ],
      ),
    ],
    habits: <String>[
      'Clear the surface before you leave the room.',
      'Every document gets one home: file it, act on it or bin it.',
      'Keep one tray for live papers and nothing more.',
    ],
  ),
  _DemoBank(
    observations: <String>[
      'Cups and mugs are sitting out on the surface.',
      'Plates and bowls are stacked loosely near the edge.',
      'The counter is doing double duty as a storage place.',
    ],
    suggestions: <_Suggestion>[
      _Suggestion(
        title: 'Stack the cups and mugs by size in one column',
        detail:
            'One column of stacked cups takes a quarter of the space and '
            'stops mugs knocking into each other.',
        steps: <String>[
          'Collect every cup and mug into one group.',
          'Stack them biggest at the bottom and smallest on top.',
          'Put the column on one shelf edge and keep it there.',
        ],
      ),
      _Suggestion(
        title: 'Wash the dishes in one batch',
        detail:
            'One batch of washing up finishes the pile faster than sorting '
            'dirty from clean.',
        steps: <String>[
          'Scrape the leftovers into the bin.',
          'Fill the sink with warm water and wash the whole stack.',
          'Dry and put the clean pieces away before you wipe the counter.',
        ],
      ),
      _Suggestion(
        title: 'Move the plates into one shallow stack',
        detail:
            'Plates stored flat in a single stack are easy to pull out and '
            'never topple.',
        steps: <String>[
          'Gather the plates from every surface.',
          'Stack them in one column in the rack or cupboard.',
          'Keep the plates you use every day at the front of the stack.',
        ],
      ),
      _Suggestion(
        title: 'Clear the counter down to one tray',
        detail:
            'A cleared counter gives you space to cook and to notice the '
            'next pile early.',
        steps: <String>[
          'Put every item that is not for cooking into one tray or box.',
          'Carry the tray to the shelf where it belongs.',
          'Wipe the counter and leave the middle completely empty.',
        ],
      ),
    ],
    habits: <String>[
      'Dishes go back to the same shelf every time.',
      'Keep the counter clear so you can see the mess early.',
      'Empty the drying rack before you start a new batch.',
    ],
  ),
  _DemoBank(
    observations: <String>[
      'Clothes are resting on the floor in loose piles.',
      'Cables are tangled and run across the walking area.',
      'A few items are only kept because there is no box for them.',
    ],
    suggestions: <_Suggestion>[
      _Suggestion(
        title: 'Corral every cable into one box',
        detail:
            'Tangled cables take more space than they need and are easy to '
            'lose under the furniture.',
        steps: <String>[
          'Pull every charger and cable out of the tangle.',
          'Coil each one and tie it with a band or a tie.',
          'Drop the coils into one labelled box and keep the box in one drawer.',
        ],
      ),
      _Suggestion(
        title: 'Fold the clothes and line them up in one stack',
        detail:
            'Folded clothes in one stack look finished and take half the '
            'space of a loose pile.',
        steps: <String>[
          'Spread the clothes out on the bed or the floor.',
          'Fold each item and stack it in the order you wear it.',
          'Keep the three items for this week on top of the stack.',
        ],
      ),
      _Suggestion(
        title: 'Clear the floor into one walking lane',
        detail:
            'A clear floor is the fastest way to make a small space feel '
            'bigger and safer.',
        steps: <String>[
          'Sweep every loose item into one pile in the middle of the floor.',
          'Sort the pile into keep, relocate and bin.',
          'Relocate the keepers and leave the floor empty from wall to wall.',
        ],
      ),
      _Suggestion(
        title: 'Give every odds and ends a labelled home',
        detail:
            'Items without a home always end up back on the floor, so give '
            'them a box.',
        steps: <String>[
          'Choose one small box for the loose odds and ends.',
          'Label the front of the box.',
          'Fill the box and put it back in the same place every time.',
        ],
      ),
    ],
    habits: <String>[
      'Nothing stays on the floor overnight.',
      'Cables are coiled and boxed the moment they are unpacked.',
      'Fold clothes straight into the stack, never onto a chair.',
    ],
  ),
];
