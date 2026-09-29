import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebutton/main.dart';

void main() {
  testWidgets('Shows the empty list and explains the download placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Items'), findsOneWidget);
    expect(find.textContaining('No items yet.'), findsOneWidget);
    await tester.tap(find.text('Download items'));
    await tester.pump();
    expect(find.text('Downloads are coming soon.'), findsOneWidget);
  });

  testWidgets('Displays supplied items in the list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DownloadScreen(items: ['First file', 'Second file']),
      ),
    );

    expect(find.text('First file'), findsOneWidget);
    expect(find.text('Second file'), findsOneWidget);
    expect(find.textContaining('No items yet.'), findsNothing);
  });
}
