import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_placeholder_page.dart';
import '../../features/auth/presentation/pages/profile_placeholder_page.dart';
import '../../features/classroom/presentation/pages/classroom_placeholder_page.dart';
import '../../features/flashcard_set/presentation/pages/library_placeholder_page.dart';
import '../../features/home/presentation/pages/home_placeholder_page.dart';
import '../../features/quiz/presentation/pages/quiz_placeholder_page.dart';
import '../widgets/bottom_nav_shell.dart';
import 'routes.dart';

/// The app-wide [GoRouter] instance.
///
/// Wave 1 has no `authStateProvider` yet (Firebase doesn't exist until
/// Wave 2/3), so `redirect` is a no-op for now.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: kHomeRoute,
    debugLogDiagnostics: true,
    // TODO(01-05): wire authStateProvider redirect once core providers land
    redirect: (context, state) => null,
    routes: [
      GoRoute(
        path: kLoginRoute,
        builder: (context, state) => const LoginPlaceholderPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kHomeRoute,
                builder: (context, state) => const HomePlaceholderPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kLibraryRoute,
                builder: (context, state) => const LibraryPlaceholderPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kClassroomRoute,
                builder: (context, state) => const ClassroomPlaceholderPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kQuizRoute,
                builder: (context, state) => const QuizPlaceholderPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kProfileRoute,
                builder: (context, state) => const ProfilePlaceholderPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
