# Requirements: Memocard

**Defined:** 2026-07-18
**Core Value:** Học sinh học flashcard xong làm bài kiểm tra sinh ra từ chính bộ thẻ đó, và cả học sinh lẫn giáo viên đều nhìn thấy được kết quả trí nhớ.

Nguồn: `SRS Document - PRM393_GR6.docx` (~60 use case) + 35 màn hình thiết kế Stitch + quyết định trong `.planning/PROJECT.md`.

---

## v1 Requirements

### Foundation — Nền móng kỹ thuật

- [ ] **FND-01**: Ứng dụng khởi động và chạy được trên Android emulator
- [ ] **FND-02**: Ứng dụng khởi động và chạy được trên Windows desktop
- [ ] **FND-03**: SQLite mở và ghi được database trên cả Android lẫn Windows qua `sqflite_common_ffi`
- [ ] **FND-04**: Firebase khởi tạo thành công trên cả Android lẫn Windows
- [ ] **FND-05**: CSDL local có đủ 18 bảng theo ERD, kèm metadata đồng bộ (`server_id`, `dirty_at`, `synced_at`)
- [ ] **FND-06**: Firestore có đủ 5 root collection + subcollection theo thiết kế, kèm security rules cơ bản
- [ ] **FND-07**: Riverpod cung cấp 7 core provider dùng chung cho mọi module
- [ ] **FND-08**: GoRouter điều hướng được giữa 5 tab và tự chuyển hướng theo trạng thái đăng nhập
- [ ] **FND-09**: Theme sáng/tối dựng từ design system "Academic Precision"
- [ ] **FND-10**: Repository base class hiện thực đúng luồng đọc cache-first và ghi Firestore-first
- [ ] **FND-11**: Firestore Emulator chạy được local để phát triển không tốn quota
- [ ] **FND-12**: Nhóm có tài liệu `CONTRIBUTING.md`, `GIT_WORKFLOW.md`, `DEVELOPER_GUIDE.md`, `ENVIRONMENT.md`

### Authentication & Profile — Người 1

- [ ] **AUTH-01**: Khách đăng ký tài khoản bằng username, email, mật khẩu và xác nhận mật khẩu *(UC01)*
- [ ] **AUTH-02**: Hệ thống báo lỗi rõ ràng khi email đã tồn tại, mật khẩu không khớp, hoặc thiếu trường bắt buộc *(UC01)*
- [ ] **AUTH-03**: Người dùng đăng nhập bằng email/username và mật khẩu *(UC02)*
- [ ] **AUTH-04**: Hệ thống chặn đăng nhập và báo lỗi khi tài khoản bị khoá *(UC02)*
- [ ] **AUTH-05**: Người dùng đăng xuất và bị đưa về màn đăng nhập *(UC03)*
- [ ] **AUTH-06**: Phiên đăng nhập và role được lưu qua SharedPreferences, mở lại app không phải đăng nhập lại *(UC02)*
- [ ] **PROF-01**: Người dùng xem hồ sơ cá nhân gồm họ tên, email, username, role, trạng thái tài khoản *(UC04)*
- [ ] **PROF-02**: Người dùng cập nhật họ tên, số điện thoại, địa chỉ, avatar *(UC05)*
- [ ] **PROF-03**: Người dùng đổi mật khẩu sau khi xác thực mật khẩu hiện tại *(UC06)*
- [ ] **PROF-04**: Người dùng đổi theme sáng/tối và ngôn ngữ, lưu qua SharedPreferences *(màn Cài đặt)*

### Admin — Người 1

- [ ] **ADM-01**: Admin xem danh sách user gồm username, email, role, trạng thái *(UC07)*
- [ ] **ADM-02**: Admin tìm kiếm và lọc user theo username, email, role, trạng thái *(UC08)*
- [ ] **ADM-03**: Admin xem chi tiết user gồm ngày tạo và hoạt động *(UC09)*
- [ ] **ADM-04**: Admin đổi role của user giữa admin/teacher/student *(UC10)*
- [ ] **ADM-05**: Admin khoá hoặc mở khoá tài khoản, có hộp thoại xác nhận *(UC11)*
- [ ] **ADM-06**: Admin xoá tài khoản, có hộp thoại xác nhận *(UC12)*
- [ ] **ADM-07**: Admin reset mật khẩu user và hệ thống gửi email đặt lại *(UC13)*
- [ ] **ADM-08**: Admin xem trạng thái tài khoản (active/locked/inactive) *(UC14)*
- [ ] **ADM-09**: Admin xem và chỉnh ma trận quyền theo role *(UC15)*
- [ ] **ADM-10**: Người không phải admin bị chặn truy cập mọi màn Admin *(UC07–15 alt flow)*

### Flashcard Set — Người 2

- [ ] **SET-01**: Người dùng tạo bộ thẻ với tiêu đề, mô tả, chế độ hiển thị private/public *(UC16)*
- [ ] **SET-02**: Người dùng thêm nhiều thẻ (mặt trước / mặt sau) vào bộ thẻ khi tạo *(UC16)*
- [ ] **SET-03**: Hệ thống chặn lưu khi tiêu đề trống hoặc bộ thẻ chưa có thẻ nào *(UC16)*
- [ ] **SET-04**: Người dùng xem danh sách bộ thẻ khả dụng *(UC17)*
- [ ] **SET-05**: Người dùng tìm kiếm bộ thẻ theo từ khoá và thấy thông báo khi không có kết quả *(UC17)*
- [ ] **SET-06**: Người dùng xem chi tiết bộ thẻ và toàn bộ thẻ bên trong *(UC18)*
- [ ] **SET-07**: Chủ sở hữu sửa thông tin bộ thẻ và thêm/sửa/xoá từng thẻ *(UC19)*
- [ ] **SET-08**: Chủ sở hữu xoá bộ thẻ sau khi xác nhận *(UC20)*
- [ ] **SET-09**: Người dùng nhân bản bộ thẻ thành bản sao độc lập của mình *(UC21)*
- [ ] **SET-10**: Học sinh đánh dấu và bỏ đánh dấu bộ thẻ yêu thích *(UC22)*
- [ ] **SET-11**: Học sinh xem danh sách bộ thẻ yêu thích *(UC23)*
- [ ] **SET-12**: Người không phải chủ sở hữu không sửa/xoá được bộ thẻ *(UC19, UC20 alt flow)*

### Learning Mode — Người 3

- [ ] **LRN-01**: Học sinh chọn bộ thẻ để bắt đầu phiên học *(UC24)*
- [ ] **LRN-02**: Học sinh cấu hình phiên học (xáo thẻ, mặt hiển thị trước) trước khi bắt đầu *(UC24)*
- [ ] **LRN-03**: Học sinh lật thẻ để xem mặt sau *(UC25)*
- [ ] **LRN-04**: Học sinh đánh dấu thẻ là đã thuộc hoặc chưa thuộc *(UC25)*
- [ ] **LRN-05**: Học sinh xem tiến độ trong phiên (đã học / tổng, số đã thuộc / chưa thuộc) *(UC25)*
- [ ] **LRN-06**: Hệ thống lưu trạng thái phiên khi học sinh thoát giữa chừng *(UC25 alt flow)*
- [ ] **LRN-07**: Học sinh tiếp tục phiên học đang dở từ đúng vị trí đã dừng *(UC26)*
- [ ] **LRN-08**: Học sinh xem kết quả phiên học sau khi hoàn thành *(UC27)*
- [ ] **LRN-09**: Học sinh đặt lại tiến độ học của một bộ thẻ *(UC28)*
- [ ] **LRN-10**: Học sinh xem tiến độ học tập cá nhân tổng hợp trên dashboard *(UC29)*
- [ ] **LRN-11**: Học sinh xem tiến độ theo từng bộ thẻ *(UC29)*
- [ ] **LRN-12**: Học sinh ôn lại riêng những thẻ đã đánh dấu chưa thuộc *(UC30)*
- [ ] **LRN-13**: Học sinh học được bộ thẻ đã cache khi không có mạng *(offline-first)*

### Classroom — Người 4

- [ ] **CLS-01**: Giáo viên tạo lớp học với tên, mô tả, trường; hệ thống tự sinh mã tham gia 6 chữ số duy nhất *(UC36, UC41)*
- [ ] **CLS-02**: Giáo viên cập nhật thông tin lớp *(UC37)*
- [ ] **CLS-03**: Giáo viên xoá lớp sau khi xác nhận *(UC38)*
- [ ] **CLS-04**: Giáo viên xem danh sách lớp mình dạy *(UC39)*
- [ ] **CLS-05**: Học sinh xem danh sách lớp mình tham gia *(UC39)*
- [ ] **CLS-06**: Người dùng xem chi tiết lớp với 3 tab: thành viên, bộ thẻ, hoạt động *(UC40)*
- [ ] **CLS-07**: Giáo viên xem mã tham gia của lớp và bật/tắt cho phép tham gia bằng mã; giáo viên không tự đặt được mã *(UC41)*
- [ ] **CLS-08**: Học sinh nhập mã lớp và xác nhận để tham gia *(UC42)*
- [ ] **CLS-09**: Hệ thống báo lỗi khi mã lớp sai, đã tắt, hoặc học sinh đã ở trong lớp *(UC42 alt flow)*
- [ ] **CLS-10**: Học sinh rời khỏi lớp *(UC43)*
- [ ] **CLS-11**: Giáo viên thêm thành viên vào lớp *(UC44)*
- [ ] **CLS-12**: Giáo viên xoá thành viên khỏi lớp *(UC45)*
- [ ] **CLS-13**: Giáo viên giao bộ thẻ cho lớp kèm hạn nộp *(UC46)*
- [ ] **CLS-14**: Học sinh xem các bộ thẻ được giao và trạng thái làm của mình *(UC47)*
- [ ] **CLS-15**: Giáo viên xem tiến độ làm bộ thẻ được giao của cả lớp *(UC48)*
- [ ] **CLS-16**: Người dùng xem dòng hoạt động của lớp *(UC49)*

### Quiz / Test — Người 5

- [ ] **QUZ-01**: Giáo viên tạo bài kiểm tra với tiêu đề, mô tả, giới hạn thời gian, số câu, thứ tự câu/đáp án *(UC50)*
- [ ] **QUZ-02**: Giáo viên sinh câu hỏi trắc nghiệm từ một bộ thẻ nguồn *(UC50)*
- [ ] **QUZ-03**: Giáo viên soạn và sửa từng câu hỏi cùng 4 đáp án, đánh dấu đáp án đúng *(UC50, UC51)*
- [ ] **QUZ-04**: Giáo viên lưu bài kiểm tra ở trạng thái nháp *(UC51)*
- [ ] **QUZ-05**: Giáo viên lưu trữ (archive) bài kiểm tra *(UC52)*
- [ ] **QUZ-06**: Giáo viên xuất bản bài kiểm tra và giao cho lớp *(UC53)*
- [ ] **QUZ-07**: Giáo viên xem danh sách bài kiểm tra của mình kèm trạng thái *(UC55)*
- [ ] **QUZ-08**: Học sinh xem danh sách bài kiểm tra được giao *(UC55A)*
- [ ] **QUZ-09**: Học sinh làm bài kiểm tra, chọn đáp án, chuyển câu trước/sau *(UC56)*
- [ ] **QUZ-10**: Hệ thống hiển thị đồng hồ đếm ngược và tiến độ câu hỏi khi làm bài *(UC56)*
- [ ] **QUZ-11**: Học sinh nộp bài kiểm tra *(UC57)*
- [ ] **QUZ-12**: Hệ thống tự động chấm điểm và lưu số câu đúng, tổng câu, thời gian làm *(UC58)*
- [ ] **QUZ-13**: Học sinh xem kết quả bài làm của mình kèm đáp án đúng/sai từng câu *(UC59)*
- [ ] **QUZ-14**: Giáo viên xem kết quả toàn lớp cho một bài kiểm tra *(UC60)*
- [ ] **QUZ-15**: Học sinh không làm lại được bài đã nộp *(UC56 business rule)*

### Team Collaboration

- [ ] **TEAM-01**: Có tài liệu phân công rõ 5 người, mỗi người ≥ 4 màn hình
- [ ] **TEAM-02**: Mỗi người sở hữu trọn một thư mục `lib/features/<module>/`, không import chéo module
- [ ] **TEAM-03**: Lịch sử git thể hiện rõ đóng góp của từng người qua branch và commit message
- [ ] **TEAM-04**: Luồng E2E chạy trọn: đăng ký → đăng nhập → tạo bộ thẻ → học → tạo quiz từ bộ thẻ → giao cho lớp → học sinh làm → cả 2 phía xem kết quả

---

## v2 Requirements

Ghi nhận nhưng không nằm trong roadmap hiện tại.

### Notifications
- **NOTF-01**: Nhắc học tập hàng ngày qua local notification
- **NOTF-02**: Thông báo trong app khi giáo viên giao bài mới
- **NOTF-03**: Người dùng bật/tắt từng loại thông báo

### Media
- **MED-01**: Upload ảnh cho flashcard qua Firebase Storage
- **MED-02**: Upload/phát audio phát âm cho flashcard
- **MED-03**: Upload avatar người dùng lên Storage

### Analytics
- **ANL-01**: Biểu đồ tiến độ học theo thời gian
- **ANL-02**: Thống kê câu hỏi sai nhiều nhất trong lớp
- **ANL-03**: Xuất kết quả lớp ra CSV/Excel

### Import/Export
- **IMP-01**: Nhập bộ thẻ từ file CSV
- **IMP-02**: Xuất bộ thẻ ra CSV

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Firebase Cloud Messaging (FCM) | Không hỗ trợ Flutter Windows desktop, xung đột với yêu cầu chạy trên Windows |
| Push notification thời gian thực | Hệ quả của việc bỏ FCM — học sinh thấy bài mới khi mở app / pull-to-refresh |
| Đồng bộ 2 chiều SQLite ↔ Firestore | Quá phức tạp cho phạm vi môn học; SQLite chỉ là cache một chiều |
| Thuật toán spaced repetition (SM-2/Anki) | `CardProgress` chỉ lưu known/unknown + `review_count`, không làm lịch ôn thông minh |
| Câu hỏi tự luận trong Quiz | Không chấm tự động được; ERD chỉ hỗ trợ `QuizOption.is_correct` |
| Học sinh sửa bộ thẻ do giáo viên giao | Chỉ chủ sở hữu sửa được; muốn sửa thì Duplicate Set |
| Chỉnh sửa cộng tác nhiều người trên 1 bộ thẻ | Cần xử lý xung đột thời gian thực, ngoài phạm vi |
| Upload ảnh/audio lên Firebase Storage | Giảm phạm vi; v1 chỉ nhận URL nếu cần |
| Tính năng trả phí "Flashcard+" | Có trong mockup nhưng không có nghiệp vụ thanh toán trong SRS |
| Chế độ "Tự luận" ở màn Cài đặt | Có trong mockup nhưng mâu thuẫn với quyết định chỉ làm trắc nghiệm |
| UC31–35 | Thiếu trong bản SRS, không có mô tả để triển khai |
| Đăng nhập OAuth (Google/Facebook) | Email/password đủ cho v1 |
| Xác thực email khi đăng ký | Firebase hỗ trợ sẵn nhưng SRS không yêu cầu; thêm ma sát khi demo |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FND-01 | Phase 0 - Platform Spike | Pending |
| FND-02 | Phase 0 - Platform Spike | Pending |
| FND-03 | Phase 0 - Platform Spike | Pending |
| FND-04 | Phase 0 - Platform Spike | Pending |
| FND-05 | Phase 1 - Shared Foundation | Pending |
| FND-06 | Phase 1 - Shared Foundation | Pending |
| FND-07 | Phase 1 - Shared Foundation | Pending |
| FND-08 | Phase 1 - Shared Foundation | Pending |
| FND-09 | Phase 1 - Shared Foundation | Pending |
| FND-10 | Phase 1 - Shared Foundation | Pending |
| FND-11 | Phase 1 - Shared Foundation | Pending |
| FND-12 | Phase 1 - Shared Foundation | Pending |
| AUTH-01 | Phase 2 - Auth, Profile & Admin | Pending |
| AUTH-02 | Phase 2 - Auth, Profile & Admin | Pending |
| AUTH-03 | Phase 2 - Auth, Profile & Admin | Pending |
| AUTH-04 | Phase 2 - Auth, Profile & Admin | Pending |
| AUTH-05 | Phase 2 - Auth, Profile & Admin | Pending |
| AUTH-06 | Phase 2 - Auth, Profile & Admin | Pending |
| PROF-01 | Phase 2 - Auth, Profile & Admin | Pending |
| PROF-02 | Phase 2 - Auth, Profile & Admin | Pending |
| PROF-03 | Phase 2 - Auth, Profile & Admin | Pending |
| PROF-04 | Phase 2 - Auth, Profile & Admin | Pending |
| ADM-01 | Phase 2 - Auth, Profile & Admin | Pending |
| ADM-02 | Phase 2 - Auth, Profile & Admin | Pending |
| ADM-03 | Phase 2 - Auth, Profile & Admin | Pending |
| ADM-04 | Phase 2 - Auth, Profile & Admin | Pending |
| ADM-05 | Phase 2 - Auth, Profile & Admin | Pending |
| ADM-06 | Phase 2 - Auth, Profile & Admin | Pending |
| ADM-07 | Phase 2 - Auth, Profile & Admin | Pending |
| ADM-08 | Phase 2 - Auth, Profile & Admin | Pending |
| ADM-09 | Phase 2 - Auth, Profile & Admin | Pending |
| ADM-10 | Phase 2 - Auth, Profile & Admin | Pending |
| SET-01 | Phase 3 - Flashcard Set | Pending |
| SET-02 | Phase 3 - Flashcard Set | Pending |
| SET-03 | Phase 3 - Flashcard Set | Pending |
| SET-04 | Phase 3 - Flashcard Set | Pending |
| SET-05 | Phase 3 - Flashcard Set | Pending |
| SET-06 | Phase 3 - Flashcard Set | Pending |
| SET-07 | Phase 3 - Flashcard Set | Pending |
| SET-08 | Phase 3 - Flashcard Set | Pending |
| SET-09 | Phase 3 - Flashcard Set | Pending |
| SET-10 | Phase 3 - Flashcard Set | Pending |
| SET-11 | Phase 3 - Flashcard Set | Pending |
| SET-12 | Phase 3 - Flashcard Set | Pending |
| LRN-01 | Phase 4 - Learning Mode | Pending |
| LRN-02 | Phase 4 - Learning Mode | Pending |
| LRN-03 | Phase 4 - Learning Mode | Pending |
| LRN-04 | Phase 4 - Learning Mode | Pending |
| LRN-05 | Phase 4 - Learning Mode | Pending |
| LRN-06 | Phase 4 - Learning Mode | Pending |
| LRN-07 | Phase 4 - Learning Mode | Pending |
| LRN-08 | Phase 4 - Learning Mode | Pending |
| LRN-09 | Phase 4 - Learning Mode | Pending |
| LRN-10 | Phase 4 - Learning Mode | Pending |
| LRN-11 | Phase 4 - Learning Mode | Pending |
| LRN-12 | Phase 4 - Learning Mode | Pending |
| LRN-13 | Phase 4 - Learning Mode | Pending |
| CLS-01 | Phase 5 - Classroom | Pending |
| CLS-02 | Phase 5 - Classroom | Pending |
| CLS-03 | Phase 5 - Classroom | Pending |
| CLS-04 | Phase 5 - Classroom | Pending |
| CLS-05 | Phase 5 - Classroom | Pending |
| CLS-06 | Phase 5 - Classroom | Pending |
| CLS-07 | Phase 5 - Classroom | Pending |
| CLS-08 | Phase 5 - Classroom | Pending |
| CLS-09 | Phase 5 - Classroom | Pending |
| CLS-10 | Phase 5 - Classroom | Pending |
| CLS-11 | Phase 5 - Classroom | Pending |
| CLS-12 | Phase 5 - Classroom | Pending |
| CLS-13 | Phase 5 - Classroom | Pending |
| CLS-14 | Phase 5 - Classroom | Pending |
| CLS-15 | Phase 5 - Classroom | Pending |
| CLS-16 | Phase 5 - Classroom | Pending |
| QUZ-01 | Phase 6 - Quiz / Test | Pending |
| QUZ-02 | Phase 6 - Quiz / Test | Pending |
| QUZ-03 | Phase 6 - Quiz / Test | Pending |
| QUZ-04 | Phase 6 - Quiz / Test | Pending |
| QUZ-05 | Phase 6 - Quiz / Test | Pending |
| QUZ-06 | Phase 6 - Quiz / Test | Pending |
| QUZ-07 | Phase 6 - Quiz / Test | Pending |
| QUZ-08 | Phase 6 - Quiz / Test | Pending |
| QUZ-09 | Phase 6 - Quiz / Test | Pending |
| QUZ-10 | Phase 6 - Quiz / Test | Pending |
| QUZ-11 | Phase 6 - Quiz / Test | Pending |
| QUZ-12 | Phase 6 - Quiz / Test | Pending |
| QUZ-13 | Phase 6 - Quiz / Test | Pending |
| QUZ-14 | Phase 6 - Quiz / Test | Pending |
| QUZ-15 | Phase 6 - Quiz / Test | Pending |
| TEAM-01 | Phase 7 - Integration & QA | Pending |
| TEAM-02 | Phase 7 - Integration & QA | Pending |
| TEAM-03 | Phase 7 - Integration & QA | Pending |
| TEAM-04 | Phase 7 - Integration & QA | Pending |

**Coverage:**
- v1 requirements: **92** total
- Mapped to phases: 92/92 ✓
- Unmapped: 0 ✓

---
*Requirements defined: 2026-07-18*
*Last updated: 2026-07-18 after roadmap creation — 92/92 requirements mapped across 8 phases (0-7)*
