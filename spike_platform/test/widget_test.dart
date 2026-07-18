// Basic Flutter widget test for the platform spike app.
//
// The default counter-demo smoke test was replaced because Task 3 of
// Plan 00-02 replaced MyApp/MyHomePage with SpikeApp/SpikeHomePage.

import 'package:flutter_test/flutter_test.dart';

import 'package:spike_platform/main.dart';

void main() {
  testWidgets('SpikeApp renders the Platform Spike app bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SpikeApp());

    expect(find.text('Platform Spike'), findsOneWidget);
    expect(find.text('Re-run SQLite Test'), findsOneWidget);
    expect(find.text('Re-run Firebase Test'), findsOneWidget);
  });
}
