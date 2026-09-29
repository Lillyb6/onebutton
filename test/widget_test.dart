import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onebutton/main.dart';

void main() {
  testWidgets(
    'GET loads only names, repeated downloads replace, Clear empties',
    (tester) async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://api.restful-api.dev/objects');
        return http.Response(
          '[{"id":"1","name":"First item","data":{"color":"Purple"}},'
          '{"id":"2","name":"Second item","data":null}]',
          200,
        );
      });
      await tester.pumpWidget(
        MaterialApp(home: DownloadScreen(client: client)),
      );
      expect(requests, 0);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Download items'));
        await tester.pumpAndSettle();
        expect(find.text('First item'), findsOneWidget);
        expect(find.text('Second item'), findsOneWidget);
        expect(find.text('Purple'), findsNothing);
      }
      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(find.text('First item'), findsNothing);
      expect(find.text('Second item'), findsNothing);
      expect(find.textContaining('No items yet.'), findsOneWidget);
      expect(requests, 2);
    },
  );

  testWidgets('Clear ignores an in-flight response', (tester) async {
    final response = Completer<http.Response>();
    final client = MockClient((_) => response.future);
    await tester.pumpWidget(MaterialApp(home: DownloadScreen(client: client)));
    await tester.tap(find.text('Download items'));
    await tester.pump();
    expect(find.text('Loading...'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Clear'));
    await tester.pump();
    response.complete(http.Response('[{"name":"Late item"}]', 200));
    await tester.pumpAndSettle();
    expect(find.text('Late item'), findsNothing);
    expect(find.textContaining('No items yet.'), findsOneWidget);
  });

  for (final response in [
    http.Response('Unavailable', 503),
    http.Response('invalid json', 200),
    http.Response('[{"id":"1"}]', 200),
  ]) {
    testWidgets('Shows a recoverable error for ${response.body}', (
      tester,
    ) async {
      var fail = true;
      final client = MockClient(
        (_) async =>
            fail ? response : http.Response('[{"name":"Recovered item"}]', 200),
      );
      await tester.pumpWidget(
        MaterialApp(home: DownloadScreen(client: client)),
      );
      await tester.tap(find.text('Download items'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not load items. Please try again.'),
        findsOneWidget,
      );
      fail = false;
      await tester.tap(find.text('Download items'));
      await tester.pumpAndSettle();
      expect(find.text('Recovered item'), findsOneWidget);
      expect(
        find.text('Could not load items. Please try again.'),
        findsNothing,
      );
    });
  }
}
