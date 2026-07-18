---
phase: 00-platform-spike
plan: 01
subsystem: infra
tags: [flutter, android, firebase, sqflite, gradle, firebase-emulator]

# Dependency graph
requires: []
provides:
  - "spike_platform/ throwaway Flutter Android-only project scaffolded and pub-get clean"
  - "Pinned Firebase (firebase_core 4.12.1, firebase_auth 6.5.6, cloud_firestore 6.7.1) + sqflite ^2.4.2 dependencies"
  - "Android Gradle config (Kotlin DSL): minSdk 24, google-services plugin wired, debug-only cleartext traffic"
  - "Dummy Firebase config (google-services.json gitignored, firebase_options_spike.dart with no real API key)"
  - "lib/platform_config.dart exporting kAuthEmulatorHost/Port, kFirestoreEmulatorHost/Port"
  - "Firebase Emulator Suite config (firebase.json ports 9099/8080/4000, firestore.rules permissive, .firebaserc)"
affects: [00-02-firebase-android-spike, 00-03-validation-report]

# Tech tracking
tech-stack:
  added: [firebase_core@4.12.1, firebase_auth@6.5.6, cloud_firestore@6.7.1, sqflite@2.4.2, firebase-tools@15.24.0]
  patterns:
    - "Platform-conditional emulator host constants (10.0.2.2 for Android, localhost otherwise) in platform_config.dart"
    - "Dummy FirebaseOptions object passed to Firebase.initializeApp(options:) instead of google-services.json-driven native init, to avoid needing a real Firebase project for the spike"

key-files:
  created:
    - spike_platform/pubspec.yaml
    - spike_platform/lib/platform_config.dart
    - spike_platform/lib/firebase_options_spike.dart
    - spike_platform/android/app/google-services.json (gitignored, not committed)
    - spike_platform/firebase.json
    - spike_platform/firestore.rules
    - spike_platform/.firebaserc
  modified:
    - spike_platform/android/app/build.gradle.kts
    - spike_platform/android/settings.gradle.kts
    - spike_platform/android/app/src/debug/AndroidManifest.xml

key-decisions:
  - "Pinned sqflite to ^2.4.2 instead of CLAUDE.md's ^2.4.3, because 2.4.3 requires Dart SDK ^3.12.0 while the installed Flutter 3.41.9 toolchain bundles Dart 3.11.5"
  - "Used minSdk = 24 instead of the plan's literal minSdk = 23, because Flutter 3.41.9's own MinSdkVersionMigration silently rewrites any explicit minSdk in the 16-23 range back to flutter.minSdkVersion (which itself resolves to 24) on every build/run — 24 satisfies Firebase's >=23 floor and is immune to that auto-migration"
  - "Adapted all Task 2 Gradle file edits to Kotlin DSL (.kts) syntax because flutter create on this Flutter version scaffolds build.gradle.kts/settings.gradle.kts, not the Groovy .gradle files the plan assumed"

patterns-established:
  - "Firebase Emulator Suite always starts with empty data (no import/export config) for Phase 0 — Phase 1 will decide on baseline seed data if needed"

requirements-completed: [FND-01, FND-04]

# Metrics
duration: 30min
completed: 2026-07-18
---

# Phase 00 Plan 01: Platform Scaffold Summary

**Dựng xong `spike_platform/` (Flutter Android-only, Kotlin DSL Gradle) với dependency Firebase/sqflite pin đúng theo CLAUDE.md (trừ 1 deviation SDK), minSdk 24 + cleartext debug-only, Firebase Emulator Suite config sẵn sàng — xác nhận bằng `flutter build apk --debug` build thành công thật sự, không chỉ dừng ở `flutter analyze`.**

## Performance

- **Duration:** ~30 min (bao gồm 2 lần `flutter build apk --debug` full ~3 phút mỗi lần)
- **Started:** 2026-07-18T21:55:00+07:00 (ước lượng)
- **Completed:** 2026-07-18T22:15:06+07:00
- **Tasks:** 3/3
- **Files modified:** 11 file chính (không tính ~20 file boilerplate do `flutter create` sinh)

## Accomplishments
- `spike_platform/` build được thật sự trên Gradle (không chỉ pub get) — chạy `flutter build apk --debug` thành công, sinh `app-debug.apk`
- Phát hiện và xử lý 2 sai lệch môi trường quan trọng trước khi chúng làm hỏng Plan 00-02/00-03: (1) `sqflite ^2.4.3` không tương thích Dart SDK hiện có, (2) Flutter tự động ghi đè `minSdk` trong khoảng 16-23 về giá trị mặc định của SDK
- Firebase Emulator Suite config đầy đủ (auth 9099, firestore 8080, UI 4000), firestore.rules permissive, không seed data
- Dummy Firebase config đã xác minh không rò rỉ credential thật (`grep AIza` = 0 khớp, `google-services.json` bị gitignore)

## Task Commits

Mỗi task được commit atomic:

1. **Task 1: Scaffold spike_platform và pin dependency** - `4b1eb2a` (feat)
2. **Task 2: Cấu hình Android (minSdk, cleartext debug, Gradle google-services plugin) + dummy Firebase config** - `345e908` (feat)
3. **Task 3: Cấu hình Firebase Emulator Suite + xác minh firebase-tools CLI** - `e84abb1` (feat)

**Plan metadata:** (commit tiếp theo, xem cuối phiên)

## Files Created/Modified
- `spike_platform/pubspec.yaml` - Pin firebase_core/firebase_auth/cloud_firestore + sqflite ^2.4.2 (adjusted)
- `spike_platform/.gitignore` - Thêm `android/app/google-services.json`
- `spike_platform/android/app/build.gradle.kts` - `minSdk = 24`, plugin `com.google.gms.google-services`
- `spike_platform/android/settings.gradle.kts` - Plugin DSL `com.google.gms.google-services` version 4.4.2
- `spike_platform/android/app/src/debug/AndroidManifest.xml` - `<application android:usesCleartextTraffic="true"/>`
- `spike_platform/android/app/google-services.json` - Dummy config, gitignored (không commit)
- `spike_platform/lib/platform_config.dart` - `kAuthEmulatorHost/Port`, `kFirestoreEmulatorHost/Port`
- `spike_platform/lib/firebase_options_spike.dart` - `spikeFirebaseOptions` (FirebaseOptions dummy)
- `spike_platform/firebase.json` - Emulator ports 9099/8080/4000, không import/export
- `spike_platform/firestore.rules` - Permissive `allow read, write: if true;`
- `spike_platform/.firebaserc` - `demo-spike-project`

## Decisions Made
- **sqflite ^2.4.2 thay vì ^2.4.3:** `sqflite 2.4.3` yêu cầu Dart SDK `^3.12.0`, nhưng Flutter 3.41.9 hiện cài chỉ bundle Dart 3.11.5 → `flutter pub get` fail version-solving nếu giữ `^2.4.3`. Dùng bản gần nhất tương thích. Không phải "cài gói khác" (không vi phạm exclusion về package install trong deviation rules) — cùng một package `sqflite`, chỉ khác version pin.
- **minSdk = 24 thay vì 23:** Trong lúc chạy `flutter build apk --debug` để xác minh Gradle sync thực sự thành công (không chỉ đọc file), phát hiện Flutter tool tự "Upgrading build.gradle.kts" và âm thầm revert `minSdk = 23` về `flutter.minSdkVersion` ở mỗi lần build (nguồn: `MinSdkVersionMigration` trong flutter_tools, regex khớp mọi `minSdk` từ 16-23). `flutter.minSdkVersion` mặc định của Flutter 3.41.9 đã là 24. Chốt `minSdk = 24` — vừa thoả yêu cầu Firebase (≥23), vừa không bị auto-migration ghi đè.
- **Kotlin DSL thay vì Groovy:** Plan giả định `android/app/build.gradle` (Groovy) nhưng `flutter create` trên phiên bản Flutter này sinh `.kts` (Kotlin DSL) mặc định. Áp dụng đúng cú pháp Kotlin DSL tương đương cho mọi thay đổi Task 2.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] sqflite ^2.4.3 không resolve được do Dart SDK không đủ mới**
- **Found during:** Task 1 (`flutter pub get` fail ngay sau khi thêm dependency)
- **Issue:** `sqflite >=2.4.3` yêu cầu Dart SDK `^3.12.0`; toolchain hiện có (Flutter 3.41.9) chỉ bundle Dart 3.11.5 → version solving failed
- **Fix:** Đổi pin sang `sqflite: ^2.4.2` (resolve về `2.4.2+1`, bản gần nhất tương thích), thêm comment giải thích lý do trong pubspec.yaml
- **Files modified:** `spike_platform/pubspec.yaml`
- **Verification:** `flutter pub get` exit code 0; `grep -c "sqflite_common_ffi" pubspec.yaml` = 0
- **Committed in:** `4b1eb2a` (Task 1 commit)

**2. [Rule 3 - Blocking] Flutter toolchain sinh Kotlin DSL (.kts) thay vì Groovy (.gradle)**
- **Found during:** Task 2 (đọc file `android/app/build.gradle.kts` sau `flutter create` ở Task 1)
- **Issue:** Plan chỉ định sửa `android/app/build.gradle`, `android/build.gradle`, `android/settings.gradle` (Groovy), nhưng `flutter create` trên phiên bản Flutter cài đặt (3.41.9) sinh ra `.kts` (Kotlin DSL) mặc định — các file Groovy đó không tồn tại
- **Fix:** Áp dụng mọi thay đổi (minSdk, google-services plugin) bằng cú pháp Kotlin DSL tương đương lên `build.gradle.kts` / `settings.gradle.kts`
- **Files modified:** `spike_platform/android/app/build.gradle.kts`, `spike_platform/android/settings.gradle.kts`
- **Verification:** `flutter build apk --debug` build thành công (Gradle sync + assembleDebug pass)
- **Committed in:** `345e908` (Task 2 commit)

**3. [Rule 1 - Bug] minSdk = 23 bị Flutter tool âm thầm revert mỗi lần build**
- **Found during:** Task 2, khi chạy `flutter build apk --debug` để xác minh Gradle config (không chỉ `flutter analyze`)
- **Issue:** Sau build đầu tiên, log in ra "Upgrading build.gradle.kts" và `minSdk = 23` bị ghi đè về `minSdk = flutter.minSdkVersion`. Truy nguồn: `MinSdkVersionMigration` trong `flutter_tools/lib/src/android/migrations/min_sdk_version_migration.dart` có regex khớp mọi `minSdk`/`minSdkVersion` giá trị 16-23 và tự động thay bằng `flutter.minSdkVersion` (bản thân giá trị này = 24 trong Flutter 3.41.9, tức sàn tối thiểu của chính Flutter đã cao hơn yêu cầu 23 của Firebase)
- **Fix:** Đổi hardcode thành `minSdk = 24` — nằm ngoài khoảng regex bị auto-migrate, vẫn thoả `>=23`
- **Files modified:** `spike_platform/android/app/build.gradle.kts`
- **Verification:** Build lại lần 2, log không còn dòng "Upgrading build.gradle.kts", `grep -n "minSdk" build.gradle.kts` xác nhận `minSdk = 24` vẫn còn nguyên sau build
- **Committed in:** `345e908` (Task 2 commit)

**4. [Rule 1 - Bug] Dummy google-services.json thiếu `project_number` khiến Gradle plugin fail**
- **Found during:** Task 2, lần build `flutter build apk --debug` đầu tiên
- **Issue:** `Execution failed for task ':app:processDebugGoogleServices' > Missing project_info/project_number object` — cấu trúc JSON dummy ban đầu (theo plan) thiếu field `project_number` mà Google Services Gradle plugin bắt buộc
- **Fix:** Thêm `"project_number": "000000000000"` vào `project_info`
- **Files modified:** `spike_platform/android/app/google-services.json` (gitignored, không commit — chỉ tồn tại trên đĩa)
- **Verification:** `flutter build apk --debug` build thành công, sinh `app-debug.apk`
- **Committed in:** Không commit trực tiếp (file gitignored); thay đổi phản ánh trong log Task 2 commit message

**5. [Rule 3 - Blocking] Comment trong code chứa literal string vi phạm acceptance-criteria grep**
- **Found during:** Task 2, khi tự chạy lại acceptance criteria (`grep -c "sqflite_common_ffi"` và `grep -c "AIza"`)
- **Issue:** Comment giải thích lý do trong `pubspec.yaml` chứa chữ "sqflite_common_ffi", và docstring trong `firebase_options_spike.dart` chứa chữ "AIza..." (dùng để mô tả lý do tránh prefix đó) — cả hai khiến grep đếm ra 1 thay vì 0 như acceptance criteria yêu cầu
- **Fix:** Viết lại comment để truyền tải cùng ý nghĩa mà không chứa literal string bị cấm
- **Files modified:** `spike_platform/pubspec.yaml`, `spike_platform/lib/firebase_options_spike.dart`
- **Verification:** `grep -c "sqflite_common_ffi" pubspec.yaml` = 0; `grep -c "AIza" firebase_options_spike.dart` = 0
- **Committed in:** `4b1eb2a` (pubspec.yaml), `345e908` (firebase_options_spike.dart)

---

**Total deviations:** 5 auto-fixed (2 Rule 1 - bug, 3 Rule 3 - blocking)
**Impact on plan:** Tất cả deviation đều cần thiết để plan thực sự build được trên môi trường thật (không chỉ thoả literal string matching). Không có scope creep — không thêm tính năng nào ngoài phạm vi plan. sqflite version pin thấp hơn CLAUDE.md 1 patch version là điểm cần theo dõi khi Foundation Phase (Phase 1) loosen version constraints.

## Issues Encountered
Không có vấn đề nào ngoài các deviation đã liệt kê ở trên — tất cả đều được auto-fix trong phạm vi Rule 1/3.

## User Setup Required
Không cần — Firebase Emulator Suite dùng project giả `demo-spike-project`, không cần tài khoản Firebase thật hay biến môi trường nào.

## Next Phase Readiness
- `spike_platform/` sẵn sàng để Plan 00-02 viết logic khởi tạo Firebase (dùng `spikeFirebaseOptions` + `platform_config.dart`) và test sqflite thật trên Android emulator
- Lưu ý cho Plan 00-02/00-03: `sqflite` đang pin `^2.4.2`, không phải `^2.4.3` như CLAUDE.md ghi — nếu grep credential-hygiene hay bất kỳ kiểm tra nào ở Plan 00-03 cần literal `2.4.3`, cần cập nhật kỳ vọng theo giá trị thực tế này
- `minSdk = 24` (không phải 23) — nếu Plan 00-02/00-03 có acceptance criteria grep `minSdkVersion 23` hoặc `minSdk = 23`, cần điều chỉnh theo giá trị thực tế 24
- Không có blocker nào chặn Plan 00-02

---
*Phase: 00-platform-spike*
*Completed: 2026-07-18*
