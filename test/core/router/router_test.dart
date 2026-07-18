import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memocard/main.dart';

void main() {
  group('5-tab GoRouter shell', () {
    testWidgets('all 5 tabs are tappable and navigate to distinct pages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MemocardApp()),
      );
      await tester.pumpAndSettle();

      const tabs = <String>[
        'Trang chủ',
        'Thư viện',
        'Lớp học',
        'Bài kiểm tra',
        'Cá nhân',
      ];

      // All 5 NavigationDestination labels are present.
      for (final label in tabs) {
        expect(find.text(label), findsWidgets);
      }

      // Starts on Trang chủ (kHomeRoute is the initialLocation).
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Trang chủ'),
        ),
        findsOneWidget,
      );

      for (final label in tabs) {
        await tester.tap(find.widgetWithText(NavigationDestination, label));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: 'Expected AppBar title "$label" to be visible after tap',
        );
      }
    });
  });
}
