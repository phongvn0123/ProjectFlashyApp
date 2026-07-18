import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memocard/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light() colorScheme.brightness is Brightness.light', () {
      expect(AppTheme.light().colorScheme.brightness, Brightness.light);
    });

    test('dark() colorScheme.brightness is Brightness.dark', () {
      expect(AppTheme.dark().colorScheme.brightness, Brightness.dark);
    });

    test(
      'light() colorScheme.primary is Action Blue Color(0xFF0066CC)',
      () {
        expect(AppTheme.light().colorScheme.primary, const Color(0xFF0066CC));
      },
    );

    test('light() and dark() colorScheme.error both equal Color(0xFFBA1A1A)', () {
      expect(AppTheme.light().colorScheme.error, const Color(0xFFBA1A1A));
      expect(AppTheme.dark().colorScheme.error, const Color(0xFFBA1A1A));
    });

    test(
      'light() elevatedButtonTheme produces a fully pill-shaped button (radius >= 100)',
      () {
        final style = AppTheme.light().elevatedButtonTheme.style;
        expect(style, isNotNull);

        final shape = style!.shape?.resolve(<WidgetState>{});
        expect(shape, isA<RoundedRectangleBorder>());

        final border = shape! as RoundedRectangleBorder;
        final radius = border.borderRadius.resolve(TextDirection.ltr);
        expect(radius.topLeft.x, greaterThanOrEqualTo(100));
      },
    );

    test('light() and dark() both use Material 3', () {
      expect(AppTheme.light().useMaterial3, isTrue);
      expect(AppTheme.dark().useMaterial3, isTrue);
    });
  });
}
