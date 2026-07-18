// Placeholder integration test for Wave 1 of Phase 1 (Shared Foundation).
//
// Purpose: satisfies 01-VALIDATION.md's Wave 0 requirement that
// `integration_test/` (and the `integration_test` dev dependency) exist
// before later plans in this phase add real SQLite/Firebase integration
// tests that require the Android platform channel (unavailable under plain
// `flutter test`). This test only proves the app entrypoint (`main()`)
// builds and pumps without throwing on a real device/emulator — it calls
// `app.main()` directly so it keeps working unmodified as `lib/main.dart`
// evolves from the `flutter create` counter-app scaffold (Task 1) to the
// real `MemocardApp` shell (Task 3) and beyond.
//
// Extended by later plans in this phase (SQLite schema creation/read,
// Firestore emulator round-trip, etc.) — do not remove.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memocard/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Memocard app builds and pumps without throwing', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
