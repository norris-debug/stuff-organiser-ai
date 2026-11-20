// Functional test gate (v0.8.18, Meiosis task-5): real coverage for the
// surfaces the QA lane tracks - the dashboard badge derives from package
// metadata, the Plan tab honors the tidy-plan storage contract, the
// duplicate-space guard reuses case-insensitive matches, and the scan
// flow's pasted recognition intake saves the plan, auto-adds the venue to
// "Your spaces" and lands confirmed/verify objects as unpacked items while
// flagged reads stay out.
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
  Future<List<XFile>> getMultiImage({
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
    // Parts start collapsed - the task lines do not exist in the tree
    // until the part is opened, so tap the header first.
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
    // The pick stage is a lazy ListView and on the default test viewport
    // the Next button sits below the fold - scroll it into view first.
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
    // The waiting bubble is a lazy ListView too: the paste action can sit
    // outside the visible viewport while still built inside the cache
    // extent, and the tap at the reported center then lands on the scroll
    // surface instead of the button (run #174). Bring it on-screen first.
    await tester.ensureVisible(find.text('Paste recognized list'));
    await tester.pump();
    await tester.tap(find.text('Paste recognized list'));
    // Mascots in the chat bubbles behind the dialog repeat forever, so
    // pumpAndSettle can never settle - pump the dialog open instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byType(TextField),
      'loose papers - 92%\nred scarf - 75%\nmystery gadget - 40%',
    );
    await tester.tap(find.text('Coach from this'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Reveal the whole coach conversation. Two details make this work:
    // (1) find.text('Next'), not find.widgetWithText(OutlinedButton, ...)
    // - the shipped Next is an OutlinedButton.icon, which builds a
    // private OutlinedButton subclass that exact-type finders never see;
    // (2) the Next cooldown reads package:clock, whose fake clock does
    // advance inside testWidgets, so the 750ms fake delay clears the
    // 700ms cooldown between taps.
    int revealGuard = 0;
    while (find.text('Next').evaluate().isNotEmpty) {
      revealGuard++;
      if (revealGuard > 40) {
        debugPrint('DIAG reveal-guard hit at 40 iterations - breaking');
        break;
      }
      await tester.tap(find.text('Next'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 750));
    }

    // Finishing the reveal auto-flows into the result page, which runs
    // the scan's leave-behinds: plan save, venue auto-add, item landing.
    await tester.pump(const Duration(milliseconds: 1000));
    // The result page also carries a repeating mascot - flush the
    // side-effect chain with fixed pumps instead of settling.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Venue auto-add (TC-24) - exactly one space, reused on rescans by
    // the duplicate guard.
    expect(state.spaces, hasLength(1));
    expect(state.spaces.single.name, 'Bedroom');

    // Confirmed + verify objects landed as unpacked items; the flagged
    // read stayed out by design.
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
}
