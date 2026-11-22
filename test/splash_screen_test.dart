// v0.8.30: SplashGate contract pins - the opening screen holds ~2.2s on
// the brand lock-up, tap skips immediately, and the gated child stays in
// the tree from frame one beneath the overlay. Bounded pumps only: both
// gate timers are plain dart:async Timers, driven through tester.pump.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff_organiser_ai/screens/splash_screen.dart';

const ValueKey<String> _logoKey = ValueKey<String>('splash_logo');
const ValueKey<String> _skipKey = ValueKey<String>('splash_skip');

Widget _host() {
  return const MaterialApp(
    home: SplashGate(child: Text('dashboard_beneath')),
  );
}

void main() {
  testWidgets('splash holds ~2.2s and releases; child builds from frame one',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host());

    // Frame one: the gated child is already mounted beneath the overlay,
    // so dashboard widgets exist while the splash shows.
    expect(find.text('dashboard_beneath'), findsOneWidget);
    expect(find.byKey(_logoKey), findsOneWidget);

    // Inside the hold: the splash is still up at 2.1s (the 2.2s hold
    // timer has not fired yet).
    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.byKey(_logoKey), findsOneWidget);

    // Hold expires: the fade begins while the overlay is still present.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(_logoKey), findsOneWidget);

    // Fade completes: the overlay leaves the tree, the child remains.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(_logoKey), findsNothing);
    expect(find.text('dashboard_beneath'), findsOneWidget);
  });

  testWidgets('tap skips the hold and releases into the app',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host());
    expect(find.byKey(_logoKey), findsOneWidget);

    await tester.tap(find.byKey(_skipKey));
    // Skip starts the fade; the overlay is still present mid-fade.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(_logoKey), findsOneWidget);

    // The fade completes well before the untapped hold would expire.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(_logoKey), findsNothing);
    expect(find.text('dashboard_beneath'), findsOneWidget);

    // Let the pending hold timer fire (a guarded no-op after the skip)
    // so no timer is left pending at test end.
    await tester.pump(const Duration(milliseconds: 1800));
  });
}
