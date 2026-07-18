# Phân công nhóm — Memocard (PRM393 GR6)

**Cập nhật:** 2026-07-18
**Quy tắc chia việc:** mỗi người sở hữu trọn một module dọc (UI + state + data), tối thiểu 4 màn hình.

---

## Tổng quan

| Người | Module | Thư mục sở hữu | REQ | Màn hình | Phase |
|-------|--------|----------------|-----|----------|-------|
| **1** | Auth + Profile + Admin | `lib/features/auth/`, `lib/features/profile/`, `lib/features/admin/` | 20 | 10 | Phase 2 |
| **2** | Flashcard Set | `lib/features/flashcard_set/` | 12 | 5 | Phase 3 |
| **3** | Learning Mode | `lib/features/learning/` | 13 | 10 | Phase 4 |
| **4** | Classroom | `lib/features/classroom/` | 16 | 7 | Phase 5 |
| **5** | Quiz / Test | `lib/features/quiz/` | 15 | 7 | Phase 6 |

**Phase 0 (Spike), Phase 1 (Foundation), Phase 7 (Integration)** — cả nhóm cùng làm, không thuộc riêng ai.

---

## Luật vàng — đọc kỹ trước khi code

### 1. Không import chéo module

```dart
// ❌ SAI — Learning import thẳng vào Flashcard Set
import 'package:memocard/features/flashcard_set/data/flashcard_repository.dart';

// ✅ ĐÚNG — đi qua Riverpod provider ở core
import 'package:memocard/core/providers/repository_providers.dart';
final sets = ref.watch(flashcardSetRepositoryProvider);
```

Tự kiểm tra trước khi push:
```bash
grep -r "import.*package:memocard/features/" lib/features/
```
Nếu ra kết quả nào (ngoài file test) → sai, phải sửa.

### 2. Không sửa `lib/core/` một mình

`core/` được khoá sau Phase 1. Cần sửa thì báo cả nhóm và tạo PR riêng, không nhét chung vào PR tính năng.

### 3. Không tự thêm package vào `pubspec.yaml`

Mỗi ngày chỉ **một người** được nhận vai trò thêm dependency. Ai cần package mới thì nhắn người đó. Đây là file conflict nhiều nhất trong dự án Flutter nhiều người.

### 4. File sinh tự động không commit

`.g.dart`, `.freezed.dart` đã nằm trong `.gitignore`. Sau mỗi lần `git pull`:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 5. Dev bằng Firestore Emulator, không dùng project thật

Spark free tier chỉ 50.000 lượt đọc/ngày. 5 người test chung là cháy trước trưa, lúc đó **cả nhóm đứng hình**. Chỉ dùng project thật khi integration và demo.

```bash
firebase emulators:start --only firestore,auth
```

### 6. Quy ước branch và commit

```
feature/<module>-<tên-ngắn>       vd: feature/quiz-auto-grading
fix/<module>-<tên-ngắn>
```

Commit message viết rõ làm gì, không viết "update", "fix bug", "commit". Lịch sử git là bằng chứng đóng góp cá nhân khi chấm điểm — commit mơ hồ = không chứng minh được mình làm gì.

---

## Người 1 — Auth + Profile + Admin

**Phase 2** · 20 requirements · 10 màn hình

### Màn hình có sẵn thiết kế
| Màn | Thư mục thiết kế |
|-----|------------------|
| Đăng nhập | `login_flashly` |
| Đăng ký tài khoản | `ng_k_t_i_kho_n` |
| Hồ sơ cá nhân | `h_s_student` |
| Cài đặt | `c_i_t_ng_d_ng` |

### Màn hình phải tự thiết kế (không có trong zip)
Bám theo `.planning/reference/ui-screens/academic_precision/DESIGN.md`:
1. Admin — Danh sách user (list + search + filter)
2. Admin — Chi tiết user
3. Admin — Đổi role
4. Admin — Khoá/Mở + Xoá tài khoản
5. Admin — Reset mật khẩu user
6. Admin — Phân quyền truy cập (ma trận role × quyền)

### Requirements
`AUTH-01..06` · `PROF-01..04` · `ADM-01..10`

### Lưu ý riêng
- **SharedPreferences** là phần bắt buộc của môn học và nằm ở người này: lưu phiên đăng nhập + role (AUTH-06), lưu theme + ngôn ngữ (PROF-04). Làm cho chắc, giảng viên sẽ hỏi.
- Bảng `User` là bảng gốc mà 4 module còn lại đều đọc — đừng đổi schema sau Phase 1 mà không báo.
- `ADM-10` (chặn non-admin) phải làm cả 2 lớp: ẩn UI **và** Firestore security rules. Chỉ ẩn UI là chưa đủ, giảng viên có thể test bằng cách gọi thẳng.
- Màn Cài đặt trong mockup có mục "Chế độ kiểm tra: Trắc nghiệm & Tự luận" và banner "Nâng cấp Flashcard+" — **bỏ cả hai**, ngoài scope.

---

## Người 2 — Flashcard Set

**Phase 3** · 12 requirements · 5 màn hình

| Màn | Thư mục thiết kế |
|-----|------------------|
| Thư viện | `th_vi_n` |
| Thư viện — danh sách thẻ | `th_vi_n_flashcard_list` |
| Tạo / Sửa bộ thẻ | `t_o_s_a_b_th` |
| Chi tiết bộ thẻ | `chi_ti_t_b_th` |
| Bộ thẻ yêu thích | `b_th_y_u_th_ch` |

### Requirements
`SET-01..12`

### Lưu ý riêng
- Module này là **nền của 3 module còn lại** — Learning, Classroom, Quiz đều cần bộ thẻ. Ưu tiên xong sớm phần đọc (`SET-04`, `SET-06`) để 3 người kia có dữ liệu thật mà test.
- Định nghĩa `FlashcardSetRepository` interface và đẩy lên sớm, kể cả khi phần thân chưa xong — 3 người kia code chống lại interface đó.
- `SET-12` (chặn người không phải chủ sở hữu) làm ở cả UI lẫn security rules.
- Cẩn thận N+1: đừng load từng thẻ cho từng bộ khi hiển thị danh sách. Lưu `card_count` denormalized vào document bộ thẻ.

---

## Người 3 — Learning Mode

**Phase 4** · 13 requirements · 10 màn hình

| Màn | Thư mục thiết kế |
|-----|------------------|
| Trang chủ | `trang_ch` |
| Dashboard | `trang_ch_dashboard` |
| Cấu hình học bài | `c_u_h_nh_h_c_b_i_updated` |
| Học bài — lật thẻ | `h_c_b_i_flashcards` |
| Học bài — biến thể | `h_c_b_i_ielts_vocab_1` |
| Tiếp tục buổi học | `ti_p_t_c_bu_i_h_c_1` |
| Kết quả buổi học | `k_t_qu_bu_i_h_c` |
| Tiến độ học tập | `ti_n_h_c_t_p` + `ti_n_h_c_t_p_stats` |
| Tiến độ bộ thẻ | `ti_n_b_th` |

### Requirements
`LRN-01..13`

### Lưu ý riêng
- **`LRN-13` (học offline) là requirement quan trọng nhất của cả dự án về mặt kỹ thuật** — nó là thứ duy nhất chứng minh SQLite cache có lý do tồn tại. Đừng để cuối cùng mới làm.
- Đây cũng là chỗ thể hiện rõ nhất **lập trình bất đồng bộ** (yêu cầu bắt buộc của môn): async/await khi load thẻ, Stream khi theo dõi tiến độ phiên.
- `ti_p_t_c_bu_i_h_c_1` và `_2` là 2 file giống hệt nhau — chỉ làm 1 màn.
- `c_u_h_nh_h_c_b_i` có 2 bản, dùng bản `_updated`.
- Denormalize mặt trước/sau của thẻ vào `SessionCard` để không phải query lại từng thẻ trong lúc học.

---

## Người 4 — Classroom

**Phase 5** · 16 requirements · 7 màn hình

| Màn | Thư mục thiết kế |
|-----|------------------|
| Lớp học — Student | `l_p_h_c_student` |
| Lớp học — Teacher | `l_p_h_c_teacher` |
| Chi tiết lớp — Thành viên | `chi_ti_t_l_p_th_nh_vi_n` |
| Chi tiết lớp — Bộ thẻ | `chi_ti_t_l_p_b_th` |
| Chi tiết lớp — Hoạt động | `chi_ti_t_l_p_ho_t_ng` |
| Tham gia lớp — nhập mã | `tham_gia_l_p_nh_p_m` |
| Xác nhận tham gia lớp | `x_c_nh_n_tham_gia_l_p` |

### Requirements
`CLS-01..16`

### Lưu ý riêng
- **Mã tham gia lớp: hệ thống tự sinh 6 chữ số, giáo viên KHÔNG tự đặt.** `Classroom.join_code` là unique key — lúc sinh phải kiểm tra trùng và sinh lại nếu đụng. Giáo viên chỉ bật/tắt qua `is_join_enabled`.
- Module nhiều requirement nhất (16) nhưng phần lớn là CRUD. Phần khó nằm ở `CLS-15` (tiến độ cả lớp) — cần aggregate, mà Firestore làm aggregate rất kém. Tính sẵn và lưu vào `AssignmentProgress` lúc ghi thay vì đếm lúc đọc.
- 3 tab chi tiết lớp dùng chung 1 route, khác nhau ở tab index — đừng làm 3 màn riêng.
- `ClassActivity` (`CLS-16`) là thứ thay thế cho push notification đã bị loại. Học sinh thấy bài mới ở đây khi mở app.

---

## Người 5 — Quiz / Test

**Phase 6** · 15 requirements · 7 màn hình

| Màn | Thư mục thiết kế |
|-----|------------------|
| Danh sách bài KT — Teacher | `danh_s_ch_b_i_ki_m_tra_teacher` |
| Danh sách bài KT — Student | `danh_s_ch_b_i_ki_m_tra_student` |
| Tạo bài KT — thông tin chung | `t_o_b_i_ki_m_tra_th_ng_tin_chung` |
| Tạo bài KT — soạn câu hỏi | `t_o_b_i_ki_m_tra_so_n_c_u_h_i` |
| Làm bài kiểm tra | `l_m_b_i_ki_m_tra_c_u_h_i_3_20` |
| Kết quả bài KT — Student | `k_t_qu_b_i_ki_m_tra_student` |
| Kết quả bài KT — Lớp | `k_t_qu_b_i_ki_m_tra_l_p` |

### Requirements
`QUZ-01..15`

### Lưu ý riêng
- **`QUZ-02` (sinh câu hỏi từ bộ thẻ) là điểm nhấn của cả sản phẩm** — đây là thứ nối flashcard với quiz, và là differentiator so với Quizlet. Thuật toán: mặt trước thẻ → câu hỏi, mặt sau → đáp án đúng, 3 đáp án nhiễu lấy ngẫu nhiên từ mặt sau các thẻ khác cùng bộ. Bộ thẻ phải có ≥ 4 thẻ mới sinh được quiz.
- Chỉ làm **trắc nghiệm 4 đáp án**, không có tự luận (không chấm tự động được).
- `QUZ-15` (không làm lại bài đã nộp) phải chặn ở security rules, không chỉ ở UI.
- Module phức tạp nhất — bắt đầu sớm, và ưu tiên theo thứ tự: tạo quiz → làm bài → chấm → xem kết quả. Phần archive (`QUZ-05`) và thứ tự ngẫu nhiên (`QUZ-01`) cắt được nếu thiếu thời gian.

---

## Thứ tự cắt scope nếu thiếu thời gian

Cắt từ trên xuống, **không cắt ngược lên**:

1. Ảnh đại diện (dùng chữ cái đầu thay thế)
2. Xáo thứ tự câu hỏi quiz
3. Giới hạn thời gian làm bài
4. Dòng hoạt động lớp (`CLS-16`) — chỉ hiện bộ thẻ được giao
5. Tiếp tục phiên học dở (`LRN-06`, `LRN-07`)
6. Nhân bản bộ thẻ (`SET-09`)
7. Ma trận phân quyền (`ADM-09`) — chuyển thành read-only
8. Thống kê quiz chi tiết — chỉ hiện đúng/sai

### Tuyệt đối không cắt
CRUD bộ thẻ · CRUD quiz · CRUD lớp · logic chấm tự động · màn kết quả cả 2 vai · luồng nhập mã tham gia lớp · vòng lặp học flashcard · học offline (`LRN-13`)

---

## Checklist trước khi demo

- [ ] Chạy được trên Android emulator
- [ ] Chạy được trên Windows desktop
- [ ] Luồng E2E trọn vẹn: đăng ký → đăng nhập → tạo bộ thẻ → học → tạo quiz từ bộ thẻ → giao cho lớp → học sinh làm → cả 2 phía xem kết quả
- [ ] Tắt mạng vẫn học được bộ thẻ đã cache, bật lại thì đồng bộ đúng
- [ ] Security rules test với cả 3 identity: student, teacher, admin
- [ ] `firestore.indexes.json` đã deploy lên project demo
- [ ] Clone sạch trên máy khác vẫn build và chạy được
- [ ] `git log` thể hiện rõ ai làm module nào
- [ ] Mỗi người demo được ít nhất 4 màn hình của mình
