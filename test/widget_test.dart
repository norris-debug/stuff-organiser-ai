// Functional test gate (v0.8.18, Meiosis task-5): the dashboard badge, the
// Plan tab storage contract, the duplicate-space guard, and the scan flow's
// pasted-recognition intake end to end.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stuff_organiser_ai/main.dart';
import 'package:stuff_organiser_ai/models/space.dart';
import 'package:stuff_organiser_ai/scan/scan_flow.dart';
import 'package:stuff_organiser_ai/screens/plan_screen.dart';
import 'package:stuff_organiser_ai/services/auth_service.dart';
import 'package:stuff_organiser_ai/services/data_service.dart';
import 'package:stuff_organiser_ai/state/app_state.dart';
import 'package:stuff_organiser_ai/state/app_state_spaces.dart';
import 'package:stuff_organiser_ai/theme/app_theme.dart';

/// A 1x1 PNG so Image.memory has decodable bytes in the widget tests.
const String _kPng1x1 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

/// Gallery double that returns in-memory photos for the scan flow.
class _FakeImagePicker extends ImagePickerPlatform {
  _FakeImagePicker(this.files);

  final List<XFile> files;

  @override
  Future<List<XFile>?> getMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async =>
      files;
}

AppState _demoState(SharedPreferences prefs) {
  return AppState(
    authService: AuthService(auth: null),
    dataService: DataService(db: null),
    prefs: prefs,
  );
}

Future<AppState> _bootstrappedState(SharedPreferences prefs) async {
  final AppState state = _demoState(prefs);
  await state.bootstrap();
  return state;
}

Widget _host(Widget child) => MaterialApp(home: child);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ImagePickerPlatform.instance = _FakeImagePicker(const <XFile>[]);
  });

  test('duplicate space guard reuses case-insensitive matches', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppState state = _demoState(prefs);

    final Space first = await state.addSpaceIfMissing('Bedroom');
    final Space second = await state.addSpaceIfMissing(' bedroom ');
    expect(second.id, first.id);
    expect(state.spaces, hasLength(1));
    expect(state.spaceByName('BEDROOM')!.id, first.id);
  });

  testWidgets('dashboard badge derives from package metadata',
      (WidgetTester tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Stuff Organiser AI',
      packageName: 'com.example.stuff_organiser_ai',
      version: '0.8.18',
      buildNumber: '38',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_complete': true,
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppState state = await _bootstrappedState(prefs);

    await tester.pumpWidget(StuffOrganiserApp(appState: state));
    // The dashboard mounts the mascot, whose idle bob repeats forever -
    // pumpAndSettle can never settle there, so pump fixed frames instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('v0.8.18+38'), findsOneWidget);
    expect(find.text('Demo mode'), findsOneWidget);
  });

  testWidgets('dashboard badge holds the web single-key format (R4-F1)',
      (WidgetTester tester) async {
    // CI stamps version.json as {"version":"0.8.23+43"}; web
    // package_info_plus parses that file, so info.version carries the full
    // string and buildNumber comes back empty. The label must render exactly
    // 'v0.8.23+43' - no dangling trailing plus.
    PackageInfo.setMockInitialValues(
      appName: 'Stuff Organiser AI',
      packageName: 'com.example.stuff_organiser_ai',
      version: '0.8.23+43',
      buildNumber: '',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_complete': true,
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppState state = await _bootstrappedState(prefs);

    await tester.pumpWidget(StuffOrganiserApp(appState: state));
    // Fixed pumps - the mascot idle bob never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('v0.8.23+43'), findsOneWidget);
    expect(find.text('v0.8.23+43+'), findsNothing);
  });

  testWidgets('plan tab renders the stored tidy plan parts',
      (WidgetTester tester) async {
    final List<Map<String, dynamic>> parts = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'part-1',
        'name': 'Bedroom',
        'tasks': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'task-1',
            'text': 'Fold the red scarf into one stack',
            'details': '',
            'done': false,
          },
        ],
      },
    ];
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tidy_plan_todo_v1': jsonEncode(parts),
    });

    await tester.pumpWidget(_host(const PlanScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Bedroom'), findsOneWidget);
    // Parts start collapsed - tap the header before asserting task texts.
    await tester.tap(find.text('Bedroom'));
    await tester.pump();
    expect(find.text('Fold the red scarf into one stack'), findsOneWidget);
  });

  testWidgets('plan tab starts empty for first runs',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_host(const PlanScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing here yet'), findsOneWidget);
  });

  testWidgets('plan tab reports a corrupt store honestly',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tidy_plan_todo_v1': 'this is not json',
    });

    await tester.pumpWidget(_host(const PlanScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('could not be read'), findsOneWidget);
    expect(find.textContaining('Nothing here yet'), findsNothing);
  });

  testWidgets('plan tab reports a valid-JSON non-List store as corrupt (R3-F1)',
      (WidgetTester tester) async {
    // A store that decodes but is not a list is corruption on the Plan
    // side - the cast must throw into the honest banner, never render.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tidy_plan_todo_v1': '{"a":1}',
    });

    await tester.pumpWidget(_host(const PlanScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('could not be read'), findsOneWidget);
    expect(find.textContaining('Nothing here yet'), findsNothing);
  });

  testWidgets(
      'scan flow: pasted recognition saves the plan, adds the venue and lands items',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppState state = _demoState(prefs);

    ImagePickerPlatform.instance = _FakeImagePicker(<XFile>[
      XFile.fromData(
        base64Decode(_kPng1x1),
        name: 'photo-1.jpg',
        mimeType: 'image/jpeg',
      ),
    ]);

    await tester.pumpWidget(_host(
      ScanFlowScreen(
        prefs: prefs,
        mascot: MascotVariant.bunny,
        pack: themePacks.first,
        appState: state,
      ),
    ));
    await tester.pump();

    // Pick stage: venue chip + one gallery photo.
    await tester.tap(find.text('Bedroom'));
    await tester.pump();
    await tester.tap(find.text('Gallery'));
    await tester.pump();
    expect(find.byType(Image), findsWidgets);

    // Next runs the (fake-timed) analysis and opens the waiting chat.
    // The pick Next sits below the fold on the test viewport (run #174).
    await tester.scrollUntilVisible(
      find.text('Next'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();

    expect(find.text('Paste recognized list'), findsOneWidget);
    // The paste action can sit outside the visible viewport (run #174).
    await tester.ensureVisible(find.text('Paste recognized list'));
    await tester.pump();
    await tester.tap(find.text('Paste recognized list'));
    // Mascots behind the dialog repeat forever - pump fixed frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byType(TextField),
      'loose papers - 92%\nred scarf - 75%\nmystery gadget - 40%',
    );
    await tester.tap(find.text('Coach from this'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // find.text('Next') because the shipped Next is an OutlinedButton.icon
    // (exact-type finders never see it), and the app's Next cooldown reads
    // clock.now() so fake time advances it between taps. The cooldown gap
    // is driven by pump(750ms) - run #181 proved that awaiting a plain
    // Future.delayed inside the loop stalls the test body.
    int revealGuard = 0;
    while (find.text('Next').evaluate().isNotEmpty) {
      revealGuard++;
      if (revealGuard > 40) {
        break;
      }
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
    }

    // v0.8.28 (R7-F2 copy): a named venue keeps its article - 'the Bedroom'.
    expect(find.textContaining('Looking at the Bedroom'), findsOneWidget);

    // Finishing the reveal auto-flows into the result page, which runs the
    // scan's leave-behinds: plan save, venue auto-add, item landing.
    await tester.pump(const Duration(milliseconds: 1000));
    // The result page also carries a repeating mascot - fixed pumps only.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Venue auto-add (TC-24) - exactly one space, reused on rescans by the
    // duplicate guard.
    expect(state.spaces, hasLength(1));
    expect(state.spaces.single.name, 'Bedroom');

    // Confirmed + verify objects landed as unpacked items; the flagged read
    // stayed out by design.
    final Set<String> names = state.items.map((item) => item.name).toSet();
    expect(names, containsAll(<String>['loose papers', 'red scarf']));
    expect(names, isNot(contains('mystery gadget')));

    // The tidy plan auto-saved into the Plan tab's storage key (TC-23):
    // one part named for the venue with one task per suggestion.
    final String raw = prefs.getString('tidy_plan_todo_v1') ?? '';
    expect(raw, isNotEmpty);
    final List<dynamic> parts = jsonDecode(raw) as List<dynamic>;
    expect(parts, hasLength(1));
    final Map<String, dynamic> part = parts.single as Map<String, dynamic>;
    expect(part['name'], 'Bedroom');
    final List<dynamic> tasks = part['tasks'] as List<dynamic>;
    expect(tasks, hasLength(2));
  });

  testWidgets(
      'scan flow: a valid-JSON non-List plan store is never silently overwritten (R3-F1)',
      (WidgetTester tester) async {
    // R3-F1: the scan save must mirror the Plan tab's cast - a store that
    // decodes but is not a list is corruption, so the save reports instead
    // of overwriting. Pin: the store still holds the corrupt object after
    // a full scan flow with a real suggestion list.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tidy_plan_todo_v1': '{"a":1}',
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppState state = _demoState(prefs);

    ImagePickerPlatform.instance = _FakeImagePicker(<XFile>[
      XFile.fromData(
        base64Decode(_kPng1x1),
        name: 'photo-1.jpg',
        mimeType: 'image/jpeg',
      ),
    ]);

    await tester.pumpWidget(_host(
      ScanFlowScreen(
        prefs: prefs,
        mascot: MascotVariant.bunny,
        pack: themePacks.first,
        appState: state,
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('Bedroom'));
    await tester.pump();
    await tester.tap(find.text('Gallery'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Next'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();

    await tester.ensureVisible(find.text('Paste recognized list'));
    await tester.pump();
    await tester.tap(find.text('Paste recognized list'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byType(TextField),
      'loose papers - 92%\nred scarf - 75%',
    );
    await tester.tap(find.text('Coach from this'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    int revealGuard = 0;
    while (find.text('Next').evaluate().isNotEmpty) {
      revealGuard++;
      if (revealGuard > 40) {
        break;
      }
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
    }
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The corrupt store must survive untouched - an overwrite here would
    // mean the save silently replaced unreadable content.
    expect(prefs.getString('tidy_plan_todo_v1'), '{"a":1}');
  });

  testWidgets(
      'scan flow: empty venue intro reads clean and the reveal announces line by line (R7-F2)',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AppState state = _demoState(prefs);

    ImagePickerPlatform.instance = _FakeImagePicker(<XFile>[
      XFile.fromData(
        base64Decode(_kPng1x1),
        name: 'photo-1.jpg',
        mimeType: 'image/jpeg',
      ),
    ]);

    await tester.pumpWidget(_host(
      ScanFlowScreen(
        prefs: prefs,
        mascot: MascotVariant.bunny,
        pack: themePacks.first,
        appState: state,
      ),
    ));
    await tester.pump();

    // No venue chip tapped - the venue input stays empty on purpose.
    await tester.tap(find.text('Gallery'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Next'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();

    await tester.ensureVisible(find.text('Paste recognized list'));
    await tester.pump();
    await tester.tap(find.text('Paste recognized list'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // v0.8.28 (QA R8-F4): six items packed onto ONE line - the shape
    // that used to be silently chopped to its first 60 characters.
    await tester.enterText(
      find.byType(TextField),
      'loose papers - 92%, red scarf - 75%, old magazine - 55%, '
          'coffee mug - 90%, desk lamp - 80%, red notebook - 65%',
    );
    await tester.tap(find.text('Coach from this'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Run #20 measured: no wait, no drafting status - tap-gated reveal.
    expect(find.textContaining('drafting'), findsNothing);

    // One Next tap reveals the intro: the empty-venue fallback reads
    // clean - never "the this space" - and the newest line announces.
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.textContaining('Looking at your space'), findsOneWidget);
    expect(find.textContaining('the this space'), findsNothing);
    expect(
      find.ancestor(
        of: find.textContaining('Looking at your space'),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Semantics && (w.properties.liveRegion ?? false),
        ),
      ),
      findsOneWidget,
    );

    // Reveal to the end: the loop exits when Next is gone - every line
    // revealed - the same shape as the full-flow test above. The closing
    // bubble itself is NOT asserted here: the coach chat is a ListView
    // and only builds the on-screen window, the closing line sits below
    // the fold in the test viewport, and the reveal scroll stalls at the
    // estimated extent inside the fake-async zone - runs #238/#239 both
    // died finding a line that was revealed but never built.
    int revealGuard = 0;
    while (find.text('Next').evaluate().isNotEmpty) {
      revealGuard++;
      if (revealGuard > 40) {
        break;
      }
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
    }

    // Finishing the reveal auto-flows into the result page (900 ms
    // handoff), which runs the scan's leave-behinds - the plan save
    // included. The BackButton only exists on the result stage, so its
    // presence proves the reveal reached the last line.
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(BackButton), findsOneWidget);

    // R8-F4 pin, state-side: the LAST pasted item reached the plan.
    // The old per-label 60-character cap chopped a packed one-line paste
    // to its first 60 characters, so 'red notebook' never entered the
    // app; with the split fix the bucket-0 suggestion ('Give the loose
    // papers and red notebook one pass...') carries it into the
    // auto-saved part.
    final String raw = prefs.getString('tidy_plan_todo_v1') ?? '';
    expect(raw, isNotEmpty);
    final List<dynamic> parts = jsonDecode(raw) as List<dynamic>;
    expect(parts, hasLength(1));
    final List<dynamic> tasks =
        (parts.single as Map<String, dynamic>)['tasks'] as List<dynamic>;
    final Set<String> taskTexts = tasks
        .map((dynamic t) => (t as Map<String, dynamic>)['text'] as String)
        .toSet();
    expect(
      taskTexts.any((String t) => t.contains('red notebook')),
      isTrue,
    );
  });
}
