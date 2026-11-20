// QA/debug affordance tests (v0.8.25): the bundled sample photos decode
// to real PNG bytes, and the affordance stays hidden unless the debug
// flag is on.
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
}
