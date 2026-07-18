# Memocard

## What This Is

Memocard là ứng dụng flashcard di động (Flutter/Android Studio) dành cho giáo viên và học sinh, giúp kiểm tra và rèn luyện trí nhớ ngắn hạn của học sinh. Học sinh học bài qua flashcard rồi được đánh giá trí nhớ qua bài kiểm tra thuật ngữ lấy từ chính bộ thẻ đó. Giáo viên dạy nhiều lớp có thể quản lý lớp học, giao bộ thẻ, tạo bài kiểm tra và theo dõi kết quả học tập của học sinh mình dạy.

Đây là đồ án môn PRM393 (nhóm GR6, 5 thành viên), nên sản phẩm vừa phải chạy đúng nghiệp vụ, vừa phải chứng minh đủ các kỹ thuật bắt buộc của môn học.

## Core Value

Học sinh học flashcard xong làm bài kiểm tra sinh ra từ chính bộ thẻ đó, và cả học sinh lẫn giáo viên đều nhìn thấy được kết quả trí nhớ — vòng lặp **học → kiểm tra → thấy tiến độ** phải chạy trọn vẹn.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(Chưa có — cần ship để validate)

### Active

<!-- Current scope. Building toward these. -->

**Nền móng kỹ thuật (bắt buộc của môn học)**
- [ ] Backend qua API call — Firebase Firestore + REST call từ Flutter
- [ ] Firebase Authentication cho đăng ký/đăng nhập/phiên
- [ ] CSDL local bằng `sqflite_common_ffi` (chạy được cả Android lẫn Windows)
- [ ] Lập trình bất đồng bộ (async/await, Future, Stream) xuyên suốt tầng data
- [ ] Riverpod quản lý toàn bộ trạng thái ứng dụng
- [ ] SharedPreferences lưu phiên đăng nhập + role, và theme/ngôn ngữ

**Nghiệp vụ**
- [ ] Auth & Profile — đăng ký, đăng nhập, đăng xuất, xem/sửa hồ sơ, đổi mật khẩu
- [ ] Admin — quản lý user, phân quyền, khoá/mở tài khoản, reset mật khẩu (15 UC theo SRS)
- [ ] Flashcard Set — tạo, xem, sửa, xoá, nhân bản bộ thẻ; đánh dấu yêu thích
- [ ] Learning Mode — chọn bộ thẻ, học flashcard, lưu/tiếp tục phiên học, xem kết quả, theo dõi tiến độ
- [ ] Classroom — giáo viên tạo/quản lý lớp, sinh mã lớp, giao bộ thẻ; học sinh tham gia lớp bằng mã
- [ ] Quiz/Test — giáo viên soạn/xuất bản bài kiểm tra từ bộ thẻ; học sinh làm bài, chấm tự động, xem kết quả cá nhân và kết quả lớp

**Cộng tác nhóm**
- [ ] Tài liệu phân công 5 người theo module dọc, mỗi người ≥ 4 màn hình
- [ ] Quy ước code/branch chung để 5 người làm song song không conflict

### Out of Scope

- **Firebase Cloud Messaging (FCM)** — FCM không hỗ trợ Flutter Windows desktop, xung đột với yêu cầu chạy trên Windows. Thay bằng local notification / thông báo in-app đọc từ bảng `ClassActivity`.
- **Đồng bộ 2 chiều SQLite ↔ Firestore** — quá phức tạp cho phạm vi môn học. SQLite chỉ đóng vai trò cache offline-first, Firestore là nguồn sự thật duy nhất.
- **Push notification thời gian thực khi giáo viên giao bài** — hệ quả của việc bỏ FCM. Học sinh thấy bài mới khi mở app / pull-to-refresh.
- **Học sinh chỉnh sửa bộ thẻ do giáo viên giao** — chỉ chủ sở hữu mới sửa được; học sinh muốn sửa thì phải Duplicate Set.
- **Câu hỏi tự luận trong Quiz** — chỉ hỗ trợ trắc nghiệm 4 đáp án (theo ERD: `QuizOption` + `is_correct`), để chấm tự động được.
- **Thuật toán spaced repetition (SM-2/Anki)** — `CardProgress` chỉ lưu known/unknown và `review_count`, không làm lịch ôn tập thông minh.
- **UC31–35** — thiếu trong bản SRS, không có mô tả nên không đưa vào scope.
- **Upload ảnh/audio cho flashcard** — ERD có `image_path`/`audio_url` nhưng bỏ Firebase Storage để giảm phạm vi; v1 chỉ nhập URL nếu cần.

## Context

**Tài liệu đầu vào đã có:**
- `SRS Document - PRM393_GR6.docx` — ~60 use case đặc tả đầy đủ (normal flow + alternative flow), chia 5 nhóm: Auth/Admin (UC1–15), Flashcard Set (UC16–23), Learning Mode (UC24–30), Classroom (UC36–49), Quiz/Test (UC50–60). Kèm ERD hoàn chỉnh 18 bảng.
- `stitch_flashly_flashcard_quiz_memory.zip` — 32 màn hình thiết kế sẵn từ Stitch, mỗi màn có `code.html` + `screen.png`. Tiếng Việt, Material 3, primary xanh `#1a73e8`, bottom nav 5 tab: Trang chủ / Thư viện / Lớp học / Bài kiểm tra / Cá nhân.

**Lược đồ dữ liệu (18 bảng từ ERD):**
`User`, `FlashcardSet`, `Flashcard`, `FavoriteSet`, `LearningSession`, `SessionCard`, `CardProgress`, `Classroom`, `ClassMember`, `AssignedSet`, `AssignmentProgress`, `ClassActivity`, `Quiz`, `QuizSource`, `QuizQuestion`, `QuizOption`, `QuizAssignment`, `QuizAttempt`, `QuizAnswer`

Các enum quan trọng: `User.role` = admin|teacher|student, `User.status` = active|locked|inactive, `FlashcardSet.visibility` = private|public, `Quiz.status` = draft|published, `QuizAttempt.status` = in_progress|submitted|expired, `CardProgress.status` = known|unknown, `LearningSession.status` = in_progress|completed.

**Khoảng trống đã phát hiện và đã xử lý trong lúc questioning:**
- SRS có 15 UC Admin nhưng zip UI **không có màn hình Admin nào** → nhóm quyết định vẫn làm đủ 15 UC, phải tự thiết kế thêm ~6 màn Admin bám theo design system của Stitch.
- SRS không mô tả backend → chọn Firebase Firestore làm backend.
- 6 module nghiệp vụ nhưng chỉ có 5 người → gộp Admin vào chung người làm Auth.

**Bối cảnh nhóm:** 5 người cùng code trên 1 repo nhưng hiện chỉ 1 người thao tác setup. Cần tài liệu phân công rõ ràng ai làm màn nào, và cần một pha nền móng chung trước khi tách nhánh để tránh 5 người code lệch chuẩn.

## Constraints

- **Tech stack**: Flutter + Android Studio — yêu cầu bắt buộc của môn PRM393.
- **Tech stack**: Riverpod cho state management — yêu cầu bắt buộc, không dùng Provider/Bloc/GetX.
- **Tech stack**: `sqflite_common_ffi` cho CSDL local — yêu cầu bắt buộc để chạy được trên Windows, không dùng `sqflite` thuần.
- **Tech stack**: Firebase (Auth + Firestore) — yêu cầu bắt buộc về BaaS và API call.
- **Tech stack**: SharedPreferences — yêu cầu bắt buộc, dùng cho phiên đăng nhập + role và theme/ngôn ngữ.
- **Compatibility**: Phải build và chạy được trên cả Android emulator lẫn Windows desktop — quyết định loại bỏ FCM.
- **Team**: 5 thành viên, mỗi người phải sở hữu ≥ 4 màn hình để có đủ dấu vết đóng góp khi chấm điểm.
- **Design**: Bám theo 32 màn hình Stitch có sẵn — không tự do redesign, chỉ bổ sung màn Admin theo cùng ngôn ngữ thiết kế.
- **Dependencies**: 5 người dùng chung 1 Firebase project (free tier Spark) — cần thống nhất security rules và tránh đụng schema.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Firebase Auth có, FCM không | FCM không hỗ trợ Flutter Windows desktop; giữ Windows là yêu cầu cứng. Notification làm bằng local notification + `ClassActivity` in-app | — Pending |
| Firestore làm backend thay vì tự viết REST API | Không phải deploy/duy trì server riêng, 5 người dùng chung 1 project free tier, vẫn thoả yêu cầu "BackEnd call API" | — Pending |
| SQLite = cache offline-first, Firestore = nguồn sự thật | Thể hiện rõ repository pattern + lập trình bất đồng bộ (2 yêu cầu của môn), tránh bài toán sync 2 chiều | — Pending |
| Làm đủ 15 UC Admin dù zip UI không có màn Admin | Bám sát SRS 100% để không bị trừ điểm phạm vi; chấp nhận tự thiết kế thêm ~6 màn | — Pending |
| Chia việc theo module dọc (feature vertical), không theo tầng ngang | Mỗi người tự làm UI + logic + data của module mình → ít conflict git, dễ chứng minh đóng góp cá nhân khi chấm | — Pending |
| Gộp Auth + Profile + Admin vào 1 người | Cùng thao tác trên bảng `User`, gộp lại tránh 2 người tranh cùng 1 bảng. Bù lại người này nhận 10 màn nhưng 6 màn Admin chỉ là CRUD list đơn giản | — Pending |
| Có Phase nền móng chung trước khi 5 người tách nhánh | App shell, routing, theme, Firebase config, SQLite schema, base repository, Riverpod providers phải chuẩn hoá trước, nếu không 5 người sẽ code lệch và conflict nặng | — Pending |
| Chỉ hỗ trợ câu hỏi trắc nghiệm 4 đáp án | ERD `QuizOption.is_correct` cho phép chấm tự động; tự luận không chấm tự động được | — Pending |
| Mã tham gia lớp tự sinh 6 chữ số, giáo viên không tự đặt | Tránh giáo viên đặt mã trùng hoặc dễ đoán. `Classroom.join_code` là unique key trong ERD — khi sinh phải kiểm tra trùng và sinh lại nếu đụng. Giáo viên chỉ bật/tắt qua `is_join_enabled` | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-07-18 after initialization*
