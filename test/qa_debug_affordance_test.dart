// QA/debug affordance tests (v0.8.25 + v0.8.27): the bundled sample
// photos decode to real PNG bytes, the affordance stays hidden unless
// the debug flag is on, and the render-level Next semantics host exposes
// exactly one accurate accessible button node.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff_organiser_ai/debug/qa_sample_assets.dart';
import 'package:stuff_organiser_ai/debug/qa_tools.dart';

void main() {
  test('sample photo assets decode to real PNG bytes', () {
    final List<Uint8List> photos = loadSamplePhotoBytes();
    expect(photos.length, 2);
    for (final Uint8List bytes in photos) {
      expect(bytes.length, greaterThan(100));
      // PNG magic header.
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50);
    }
  });

  testWidgets('sample-photos affordance is hidden unless the debug flag is on',
      (WidgetTester tester) async {
    soaiDebugMode = false;
    int injections = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SamplePhotosDebugButton(onInject: () => injections++),
      ),
    ));
    await tester.pump();
    expect(find.text('Load sample photos'), findsNothing);

    soaiDebugMode = true;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SamplePhotosDebugButton(onInject: () => injections++),
      ),
    ));
    await tester.pump();
    expect(find.text('Load sample photos'), findsOneWidget);
    await tester.tap(find.text('Load sample photos'));
    await tester.pump();
    expect(injections, 1);
    soaiDebugMode = false;
  });

  testWidgets(
      'render-level Next host: disabled state serialized on ONE button node',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SoaiSemanticsButton(
          label: 'Next',
          enabled: false,
          onTap: null,
          child: ExcludeSemantics(
            child: FilledButton(
              onPressed: null,
              child: const Text('Next'),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    // Exactly one accessible 'Next' control: the inner button's node is
    // excluded, so the host + inner pair cannot read as a duplicate.
    expect(find.bySemanticsLabel('Next'), findsOneWidget);

    // Flutter 3.29 ground truth (dartdoc-verified 18:45Z 11-20):
    // WidgetTester has neither getSemantics nor getSemanticsData, and
    // SemanticsController has no getSemantics either. The documented
    // chain is tester.semantics.find(...) -> SemanticsNode ->
    // getSemanticsData(); tester.semantics throws unless semantics are
    // enabled, which ensureSemantics() above guarantees.
    final SemanticsData data =
        tester.semantics
            .find(find.byType(SoaiSemanticsButton))
            .getSemanticsData();
    expect(data.label, 'Next');
    expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
    // The enabled-state flag must be PRESENT even while disabled - that
    // is the flag the web engine reads to emit aria-disabled.
    expect(data.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
    expect(data.hasFlag(SemanticsFlag.isEnabled), isFalse);
  });

  testWidgets(
      'render-level Next host: enabled state and tap action while enabled',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SoaiSemanticsButton(
          label: 'Next',
          enabled: true,
          onTap: () {},
          child: ExcludeSemantics(
            child: FilledButton(
              onPressed: () {},
              child: const Text('Next'),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('Next'), findsOneWidget);
    final SemanticsData data =
        tester.semantics
            .find(find.byType(SoaiSemanticsButton))
            .getSemanticsData();
    expect(data.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
    expect(data.hasFlag(SemanticsFlag.isEnabled), isTrue);
  });
}
