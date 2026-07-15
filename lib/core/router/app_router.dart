import 'package:go_router/go_router.dart';

import '../../dev/core_showcase_screen.dart';
import '../../features/home/app_shell.dart';
import '../../features/quiz/screens/quiz_list_screen.dart';
import '../constants/app_routes.dart';
import '../widgets/coming_soon_screen.dart';

/// Khai báo điều hướng toàn app bằng `go_router`.
///
/// Hiện các màn sản phẩm trỏ tạm vào [ComingSoonScreen] để app chạy & điều
/// hướng được ngay trong lúc dựng phần core. Khi build màn thật theo
/// `SCREENS.md`, thay `builder` tương ứng (giữ nguyên `path`/`name`).
///
/// `initialLocation` đặt ở [AppRoutes.home] để chạy lên là thấy ngay khung
/// app thật (Header + Footer/BottomNav). Màn dev showcase vẫn giữ ở
/// [AppRoutes.devShowcase] để xem lại bộ widget dùng chung khi cần.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    // --- DEV ---
    GoRoute(
      path: AppRoutes.devShowcase,
      builder: (_, _) => const CoreShowcaseScreen(),
    ),

    // --- Auth ---
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.nLogin,
      builder: (_, _) => const ComingSoonScreen(title: 'Đăng nhập'),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: AppRoutes.nRegister,
      builder: (_, _) => const ComingSoonScreen(title: 'Đăng ký'),
    ),

    // --- Home / Shell (Header + Footer BottomNav) ---
    GoRoute(
      path: AppRoutes.home,
      name: AppRoutes.nHome,
      builder: (_, _) => const AppShell(),
    ),

    // --- Flashcard sets ---
    GoRoute(
      path: AppRoutes.library,
      builder: (_, _) => const ComingSoonScreen(title: 'Thư viện'),
    ),
    GoRoute(
      path: AppRoutes.favourites,
      builder: (_, _) => const ComingSoonScreen(title: 'Bộ thẻ yêu thích'),
    ),

    // --- Learning mode ---
    GoRoute(
      path: AppRoutes.progress,
      builder: (_, _) => const ComingSoonScreen(title: 'Tiến độ học tập'),
    ),

    // --- Classroom ---
    GoRoute(
      path: AppRoutes.classes,
      builder: (_, _) => const ComingSoonScreen(title: 'Lớp học'),
    ),

    // --- Quiz ---
    GoRoute(path: AppRoutes.quizzes, builder: (_, _) => const QuizListScreen()),

    // --- Profile ---
    GoRoute(
      path: AppRoutes.profile,
      builder: (_, _) => const ComingSoonScreen(title: 'Hồ sơ'),
    ),
  ],
  errorBuilder: (_, state) =>
      ComingSoonScreen(title: 'Không tìm thấy trang: ${state.uri.path}'),
);
