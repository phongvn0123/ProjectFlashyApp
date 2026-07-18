---
phase: 1
slug: shared-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-18
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (bundled with Flutter 3.41.9 / Dart 3.11.5) |
| **Config file** | `pubspec.yaml` `dev_dependencies:` — no separate config file |
| **Quick run command** | `flutter analyze` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15-40 giây (`analyze` ~5s, `test` ~10-35s tuỳ số test) |

**Ghi chú quan trọng từ Phase 0:** `flutter test` chạy trên Dart VM của máy host, **không có platform channel của Android**. Nghĩa là `sqflite` và Firebase native **không hoạt động** trong `flutter test` thường. Mọi test chạm vào DB hoặc Firebase phải:
- dùng fake/in-memory implementation của repository interface, HOẶC
- là integration test chạy qua `flutter test integration_test/ -d emulator-5554`.

Đây là lý do Phase 0 thấy `[SPIKE] SQLITE FAIL: databaseFactory not initialized` trong `flutter test` dù app chạy thật trên emulator vẫn PASS. Đừng nhầm đó là hồi quy.

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 40 giây

---

## Per-Task Verification Map

Bảng này do planner điền chi tiết khi sinh PLAN.md. Khung yêu cầu tối thiểu cho từng nhóm requirement của Phase 1:

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-xx | 01 | 1 | FND-08 (routing/shell) | — | N/A | widget | `flutter test test/core/router_test.dart` | ❌ W0 | ⬜ pending |
| 01-01-xx | 01 | 1 | FND-09 (theme) | — | N/A | widget | `flutter test test/core/theme_test.dart` | ❌ W0 | ⬜ pending |
| 01-02-xx | 02 | 2 | FND-05 (18-table schema) | — | N/A | unit | `flutter test test/core/db/schema_test.dart` | ❌ W0 | ⬜ pending |
| 01-02-xx | 02 | 2 | FND-06 (Firestore schema/rules) | T-01-01 | Non-owner bị từ chối read/write | rules | `firebase emulators:exec --only firestore "flutter test test/core/rules_test.dart"` | ❌ W0 | ⬜ pending |
| 01-03-xx | 03 | 2 | FND-07 (7 core providers) | — | N/A | unit | `flutter test test/core/providers_test.dart` | ❌ W0 | ⬜ pending |
| 01-03-xx | 03 | 3 | FND-10 (base repository) | — | N/A | unit | `flutter test test/core/repository_test.dart` | ❌ W0 | ⬜ pending |
| 01-04-xx | 04 | 3 | FND-11, FND-12 (team docs) | — | N/A | manual | — (xem Manual-Only bên dưới) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Dự án chưa có bất kỳ hạ tầng test nào (`spike_platform/` là code vứt đi, không tính). Wave 0 phải dựng:

- [ ] `test/core/` — thư mục test cho tầng `core/`
- [ ] `test/helpers/fake_repositories.dart` — fake in-memory implementation của repository interface, để test business logic không cần platform channel
- [ ] `test/helpers/provider_harness.dart` — `ProviderContainer` helper với override sẵn cho `databaseProvider` / `firestoreProvider` / `sharedPrefsProvider`
- [ ] `integration_test/` + `integration_test` dev dependency — cho các test bắt buộc phải chạy trên emulator thật (sqflite, Firebase)
- [ ] `flutter_test` đã có sẵn trong `dev_dependencies` khi `flutter create` — không cần cài thêm

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App khởi động vào shell 5 tab, chuyển tab giữ được state, theme sáng/tối đúng "Academic Precision" | FND-08, FND-09 | Widget test xác nhận được cấu trúc router và token màu, nhưng "nhìn có đúng thiết kế Stitch không" là đánh giá thị giác | Chạy `flutter run -d emulator-5554`, bấm qua cả 5 tab, đổi theme hệ thống sang dark, đối chiếu với `.planning/reference/ui-screens/academic_precision/DESIGN.md` và ảnh `screen.png` của các màn Stitch |
| Dev mới clone repo và chạy được app theo tài liệu | FND-11, FND-12 | Chỉ chứng minh được bằng cách một người thật làm theo tài liệu trên máy sạch | Một thành viên khác trong nhóm clone repo mới, làm đúng theo `DEVELOPER_GUIDE.md` + `ENVIRONMENT.md`, ghi lại mọi bước bị kẹt |
| Firestore security rules chặn đúng theo role trên project chung | FND-06 | Rules test trên emulator không chứng minh được rules đã deploy đúng lên project thật của nhóm | Đăng nhập bằng 3 tài khoản student/teacher/admin thật, thử đọc/ghi tài liệu không thuộc sở hữu, xác nhận bị từ chối |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags (không dùng `flutter test --watch`)
- [ ] Feedback latency < 40s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
