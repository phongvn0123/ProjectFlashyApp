# Screen Inventory — Memocard

Ánh xạ 35 màn hình thiết kế sẵn (từ `stitch_flashly_flashcard_quiz_memory.zip`) sang use case trong SRS và người phụ trách.

Đường dẫn thiết kế: `.planning/reference/ui-screens/<slug>/` — mỗi thư mục có `code.html` (Tailwind/HTML tham chiếu) và `screen.png` (ảnh render).

Design system: `.planning/reference/ui-screens/academic_precision/DESIGN.md` ("Academic Precision" — M3 tokens, Inter, pill buttons, hairline borders).

---

## Người 1 — Auth + Profile + Admin (10 màn)

| # | Slug | Tên màn | UC | Ghi chú |
|---|------|---------|----|---------|
| 1 | `login_flashly` | Đăng nhập | UC02 | Firebase Auth signIn |
| 2 | `ng_k_t_i_kho_n` | Đăng ký tài khoản | UC01 | Firebase Auth signUp + tạo doc User |
| 3 | `h_s_student` | Hồ sơ cá nhân | UC04, UC05 | Xem + sửa profile |
| 4 | `c_i_t_ng_d_ng` | Cài đặt | UC03, UC06 | **SharedPreferences**: theme, ngôn ngữ. Có nút Đăng xuất + Đổi mật khẩu |
| 5 | — *(tự thiết kế)* | Admin — Danh sách user | UC07, UC08 | List + search/filter |
| 6 | — *(tự thiết kế)* | Admin — Chi tiết user | UC09, UC14 | Xem chi tiết + trạng thái tài khoản |
| 7 | — *(tự thiết kế)* | Admin — Đổi role | UC10 | admin / teacher / student |
| 8 | — *(tự thiết kế)* | Admin — Khoá/Mở + Xoá tài khoản | UC11, UC12 | Có dialog xác nhận |
| 9 | — *(tự thiết kế)* | Admin — Reset mật khẩu user | UC13 | Firebase Auth password reset email |
| 10 | — *(tự thiết kế)* | Admin — Phân quyền truy cập | UC15 | Ma trận role × quyền |

⚠️ 6 màn Admin **không có trong zip** — phải tự thiết kế theo `DESIGN.md`.

---

## Người 2 — Flashcard Set (5 màn)

| # | Slug | Tên màn | UC |
|---|------|---------|----|
| 1 | `th_vi_n` | Thư viện (tab Bộ thẻ) | UC17 |
| 2 | `th_vi_n_flashcard_list` | Thư viện — danh sách thẻ | UC17 |
| 3 | `t_o_s_a_b_th` | Tạo / Sửa bộ thẻ | UC16, UC19 |
| 4 | `chi_ti_t_b_th` | Chi tiết bộ thẻ | UC18, UC20, UC21 (xoá, nhân bản) |
| 5 | `b_th_y_u_th_ch` | Bộ thẻ yêu thích | UC22, UC23 |

---

## Người 3 — Learning Mode (10 màn)

| # | Slug | Tên màn | UC |
|---|------|---------|----|
| 1 | `trang_ch` | Trang chủ | — (shell) |
| 2 | `trang_ch_dashboard` | Trang chủ — Dashboard | UC29 |
| 3 | `c_u_h_nh_h_c_b_i` | Cấu hình học bài | UC24 |
| 4 | `c_u_h_nh_h_c_b_i_updated` | Cấu hình học bài (biến thể) | UC24 |
| 5 | `h_c_b_i_flashcards` | Học bài — lật thẻ | UC25 |
| 6 | `h_c_b_i_ielts_vocab_1` | Học bài — biến thể | UC25 |
| 7 | `ti_p_t_c_bu_i_h_c_1` / `_2` | Tiếp tục buổi học | UC26 |
| 8 | `k_t_qu_bu_i_h_c` | Kết quả buổi học | UC27 |
| 9 | `ti_n_h_c_t_p` + `ti_n_h_c_t_p_stats` | Tiến độ học tập | UC29 |
| 10 | `ti_n_b_th` | Tiến độ bộ thẻ | UC28, UC30 |

---

## Người 4 — Classroom (7 màn)

| # | Slug | Tên màn | UC |
|---|------|---------|----|
| 1 | `l_p_h_c_student` | Lớp học (Student) | UC39 |
| 2 | `l_p_h_c_teacher` | Lớp học (Teacher) | UC36, UC37, UC38, UC39 |
| 3 | `chi_ti_t_l_p_th_nh_vi_n` | Chi tiết lớp — Thành viên | UC40, UC44, UC45 |
| 4 | `chi_ti_t_l_p_b_th` | Chi tiết lớp — Bộ thẻ | UC46, UC47, UC48 |
| 5 | `chi_ti_t_l_p_ho_t_ng` | Chi tiết lớp — Hoạt động | UC49 |
| 6 | `tham_gia_l_p_nh_p_m` | Tham gia lớp — nhập mã | UC41, UC42 |
| 7 | `x_c_nh_n_tham_gia_l_p` | Xác nhận tham gia lớp | UC42, UC43 |

---

## Người 5 — Quiz / Test (7 màn)

| # | Slug | Tên màn | UC |
|---|------|---------|----|
| 1 | `danh_s_ch_b_i_ki_m_tra_teacher` | Danh sách bài KT (Teacher) | UC55 |
| 2 | `danh_s_ch_b_i_ki_m_tra_student` | Danh sách bài KT (Student) | UC55A |
| 3 | `t_o_b_i_ki_m_tra_th_ng_tin_chung` | Tạo bài KT — thông tin chung | UC50, UC51 |
| 4 | `t_o_b_i_ki_m_tra_so_n_c_u_h_i` | Tạo bài KT — soạn câu hỏi | UC50, UC52, UC53 |
| 5 | `l_m_b_i_ki_m_tra_c_u_h_i_3_20` | Làm bài kiểm tra | UC56, UC57 |
| 6 | `k_t_qu_b_i_ki_m_tra_student` | Kết quả bài KT (Student) | UC58, UC59 |
| 7 | `k_t_qu_b_i_ki_m_tra_l_p` | Kết quả bài KT (Lớp) | UC60 |

---

## Tổng kết

| Người | Module | Số màn | Đủ ≥4? |
|-------|--------|--------|--------|
| 1 | Auth + Profile + Admin | 10 (4 có sẵn + 6 tự thiết kế) | ✓ |
| 2 | Flashcard Set | 5 | ✓ |
| 3 | Learning Mode | 10 | ✓ |
| 4 | Classroom | 7 | ✓ |
| 5 | Quiz / Test | 7 | ✓ |

**Tổng: 39 màn** (35 có thiết kế sẵn + 4–6 màn Admin tự thiết kế)

---

## Mâu thuẫn UI ↔ Scope đã phát hiện

| Vị trí | Vấn đề | Xử lý |
|--------|--------|-------|
| `c_i_t_ng_d_ng` | Hiện "Chế độ kiểm tra: Trắc nghiệm & Tự luận" | Bỏ Tự luận — scope chỉ trắc nghiệm 4 đáp án (chấm tự động). Sửa thành "Trắc nghiệm" |
| `c_i_t_ng_d_ng` | Banner "Nâng cấp Flashcard+" (premium upsell) | Bỏ — không có tính năng trả phí |
| `c_i_t_ng_d_ng` | Toggle "Thông báo — Lời nhắc học tập hàng ngày" | Giữ, nhưng dùng `flutter_local_notifications` (không FCM) |
| Toàn bộ | Không có màn hình Admin nào | Người 1 tự thiết kế 6 màn theo `DESIGN.md` |
| `ti_p_t_c_bu_i_h_c_1` / `_2` | 2 file giống hệt nhau (cùng kích thước) | Chỉ implement 1 màn |
| `c_u_h_nh_h_c_b_i` / `_updated` | 2 biến thể của cùng 1 màn | Dùng bản `_updated`, đối chiếu bản gốc |
