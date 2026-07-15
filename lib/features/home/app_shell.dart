import 'package:flutter/material.dart';

import '../../core/widgets/coming_soon_screen.dart';
import '../quiz/screens/quiz_list_screen.dart';
import 'home_screen.dart';

/// FOOTER / khung app (SCREENS §3) — thanh điều hướng dưới cùng 5 tab.
///
/// - `Scaffold(bottomNavigationBar: NavigationBar)`; màu/kiểu lấy từ
///   `navigationBarTheme` trong `app_theme.dart` (active = Action Blue).
/// - Dùng [IndexedStack] để MỖI tab GIỮ NGUYÊN trạng thái khi chuyển qua lại
///   (không dựng lại từ đầu) — đúng ghi chú SCREENS §3.
/// - Hiện chỉ tab Home là màn thật; 4 tab còn lại tạm [ComingSoonScreen],
///   thay dần khi dựng Library / Classes / Quiz / Profile theo SCREENS.md.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  static const _tabs = <Widget>[
    HomeScreen(),
    ComingSoonScreen(title: 'Thư viện'),
    ComingSoonScreen(title: 'Lớp học'),
    QuizListScreen(),
    ComingSoonScreen(title: 'Hồ sơ'),
  ];

  void _onTap(int i) {
    if (i != _index) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Thư viện',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Lớp học',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz_rounded),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
