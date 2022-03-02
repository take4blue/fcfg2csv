import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:fcfg2csv/main.dart';

void main() {
  testWidgets('Convert 1', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    final input = find.byKey(const Key('input'));
    final output = find.byKey(const Key('output'));

    await tester.enterText(input, r"machineId=9");
    await tester.tap(find.byIcon(CupertinoIcons.square_arrow_right));
    await tester.pump();

    TextField widget = tester.widget(output);
    expect(widget.controller!.value.text, "machineId,9\n");
  });

  testWidgets('Clear 1', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    final input = find.byKey(const Key('input'));
    final output = find.byKey(const Key('output'));

    await tester.enterText(input, r"machineId=9");
    await tester.tap(find.byIcon(CupertinoIcons.square_arrow_right));
    await tester.pump();
    await tester.tap(find.byIcon(CupertinoIcons.delete));
    await tester.pump();

    TextField outWidget = tester.widget(output);
    expect(outWidget.controller!.value.text.isEmpty, isTrue);
    TextField inWidget = tester.widget(input);
    expect(inWidget.controller!.value.text.isEmpty, isTrue);
  });

  testWidgets('Paste 1', (WidgetTester tester) async {
    String clipboardContent = '';
    SystemChannels.platform
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.setData') {
        clipboardContent = methodCall.arguments['text'];
      }
      return null;
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    final input = find.byKey(const Key('input'));
    final tapArea = find.byKey(const Key('longTapArea'));

    await tester.enterText(input, r"machineId=9");
    await tester.tap(find.byIcon(CupertinoIcons.square_arrow_right));
    await tester.pump();
    await tester.tap(tapArea);
    await tester.pumpAndSettle(kLongPressTimeout);

    expect(clipboardContent, "machineId,9\n");
  }, skip: true);
}
