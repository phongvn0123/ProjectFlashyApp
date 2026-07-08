/// Tên đường dẫn (path) của các màn hình — khớp với `SCREENS.md`.
///
/// Dùng hằng số thay vì gõ chuỗi thẳng để tránh sai chính tả khi điều hướng.
/// `name` dùng cho `context.goNamed(...)`, `path` dùng khi khai báo route.
class AppRoutes {
  AppRoutes._();

  // --- Auth (SCREENS §1, §2) ---
  static const login = '/login';
  static const register = '/register';

  // --- Shell + Home (SCREENS §3) ---
  static const home = '/home';

  // --- Flashcard sets (SCREENS §4, §4B, §5, §6) ---
  static const library = '/library';
  static const favourites = '/library/favourites';
  static const setDetail = '/library/set'; // + /:id
  static const setEditor = '/library/set/edit'; // + /:id? (null = tạo mới)

  // --- Learning mode (SCREENS §6B, §6C, §7, §8, §8B, §8C) ---
  static const studyOptions = '/study/options'; // + /:setId
  static const study = '/study'; // + /:setId
  static const sessionResult = '/study/result'; // + /:sessionId
  static const progress = '/progress';
  static const progressDetail = '/progress/set'; // + /:setId

  // --- Classroom (SCREENS §9–§10C) ---
  static const classes = '/classes';
  static const classEditor = '/classes/edit'; // + /:id?
  static const classDetail = '/classes/detail'; // + /:id
  static const addMember = '/classes/detail/add-member'; // + /:classId

  // --- Quiz (SCREENS §11–§13) ---
  static const quizzes = '/quizzes';
  static const quizEditor = '/quizzes/edit'; // + /:id?
  static const quizDetail = '/quizzes/detail'; // + /:id
  static const publishQuiz = '/quizzes/publish'; // + /:id
  static const takeQuiz = '/quizzes/take'; // + /:id
  static const quizResult = '/quizzes/result'; // + /:attemptId

  // --- Profile (SCREENS §14–§14C) ---
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const changePassword = '/profile/change-password';

  // --- Dev only: showcase các widget dùng chung (xoá khi xong core) ---
  static const devShowcase = '/dev/showcase';

  /// Tên route dạng named (trùng path để gọn) cho `goNamed`.
  static const nLogin = 'login';
  static const nRegister = 'register';
  static const nHome = 'home';
}
