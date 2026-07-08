import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flashly_app/app.dart';
import 'package:flashly_app/core/widgets/app_button.dart';

void main() {
  testWidgets('App khởi động & hiển thị màn showcase phần core', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlashlyApp()));
    await tester.pumpAndSettle();

    // Showcase là màn khởi đầu (initialLocation) → thấy tiêu đề + phần typography trên đầu.
    expect(find.text('Core — Shared widgets'), findsOneWidget);
    expect(find.text('Hero display'), findsOneWidget);

    // Cuộn xuống để các AppButton (nằm dưới) được dựng, rồi kiểm tra.
    await tester.dragUntilVisible(
      find.text('Danger — Xoá'),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    expect(find.byType(AppButton), findsWidgets);
  });
}
