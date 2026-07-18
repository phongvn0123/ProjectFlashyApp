import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Persistent 5-tab bottom navigation shell.
///
/// Wraps the [StatefulShellRoute.indexedStack] branch content; per
/// DESIGN.md Components > Navigation: "88px height ... icons 24px,
/// inkMuted48 inactive, Action Blue active" (active/inactive colors come
/// from the applied [ThemeData.colorScheme] via [NavigationBar]'s default
/// Material 3 styling).
class BottomNavShell extends ConsumerWidget {
  const BottomNavShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 88,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Thư viện',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_rounded),
            label: 'Lớp học',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_rounded),
            label: 'Bài kiểm tra',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
