---
phase: 00-platform-spike
plan: 03
subsystem: infra
tags: [flutter, android, firebase, sqflite, firebase-emulator, gradle, ci-evidence]

# Dependency graph
requires:
  - phase: 00-platform-spike (plan 01)
    provides: "spike_platform/ scaffolded project, pinned dependencies, platform_config.dart, firebase_options_spike.dart, Firebase Emulator Suite config"
  - phase: 00-platform-spike (plan 02)
    provides: "testSqliteInsertAndRead(), testFirebaseInitAuthFirestore(), main.dart wiring both to auto-run on launch"
provides:
  - "Empirical GO verdict for Phase 0 (.planning/phases/00-platform-spike/00-SPIKE-FINDINGS.md) — Firebase + sqflite proven to work on real Android emulator against a live Firebase Emulator Suite"
  - "Captured evidence: spike_platform/spike_run.log (gitignored, on-disk) and evidence/spike-screenshot.png (committed)"
  - "Fix for a real Firebase duplicate-app crash pattern that Phase 1 will need to repeat when wiring the real Firebase project"
affects: [01-shared-foundation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Catch FirebaseException code 'duplicate-app' around Firebase.initializeApp() when google-services.json is present, because the Google Services Gradle plugin auto-initializes a native default FirebaseApp via ContentProvider before Dart main() runs — Firebase.apps.isEmpty cannot detect this since the Dart-side cache always starts empty"
    - "On Windows Git Bash, PATH/JAVA_HOME overrides must use POSIX-style paths (/c/Program Files/...) not Windows-style (C:/Program Files/...) or the override silently fails to resolve"

key-files:
  created:
    - .planning/phases/00-platform-spike/00-SPIKE-FINDINGS.md
    - .planning/phases/00-platform-spike/evidence/spike-screenshot.png
    - spike_platform/spike_run.log (gitignored, evidence only, not committed)
  modified:
    - spike_platform/lib/main.dart

key-decisions:
  - "Caught FirebaseException(code: 'duplicate-app') instead of checking Firebase.apps.isEmpty, because the Dart-side Firebase.apps list always starts empty regardless of native pre-initialization state — the isEmpty check cannot prevent the crash"
  - "Used the Android Studio-bundled JBR (JDK 21) for firebase-tools instead of installing a new JDK, since firebase-tools v15+ requires Java 21+ and the system default (Oracle Java 8) is too old"
  - "Used flutter run -d emulator-5554 instead of the plan's -d android, since 'android' is not a valid device id in this Flutter version — it must be the exact device id from flutter devices"

patterns-established:
  - "Real Firebase projects (Phase 1+) using google-services.json must guard Firebase.initializeApp() against the native auto-init duplicate-app crash the same way this spike does"

requirements-completed: [FND-01, FND-03, FND-04]

# Metrics
duration: ~35min
completed: 2026-07-18
---

# Phase 00 Plan 03: Real-Device Spike Evidence + GO Verdict Summary

**Chạy `spike_platform` thật trên Android emulator (Google APIs system image) đối chọi Firebase Emulator Suite đang chạy nền, thu log `[SPIKE] SQLITE PASS` + `[SPIKE] FIREBASE PASS` và screenshot làm bằng chứng, phát hiện và sửa 1 bug crash thật (`duplicate-app` FirebaseException), rồi viết `00-SPIKE-FINDINGS.md` với verdict GO — Phase 1 được phép bắt đầu.**

## Performance

- **Duration:** ~35 min (bao gồm thời gian tìm JDK 21 thay thế, debug bug duplicate-app, và 3 lần build/run Gradle)
- **Started:** 2026-07-18T22:20:00+07:00 (ước lượng)
- **Completed:** 2026-07-18T22:50:00+07:00 (ước lượng)
- **Tasks:** 3/3
- **Files modified:** 1 code file (`main.dart`) + 2 evidence artifacts (screenshot committed, log gitignored)

## Accomplishments
- 4 kiểm tra tĩnh (Task 1) đều pass: không FFI/API key thật trong source, `google-services.json` gitignored, `flutter analyze` sạch
- Chạy được app THẬT trên `emulator-5554` (AVD `Pixel_6`, xác nhận `tag.id=google_apis` qua config.ini) với Firebase Emulator Suite thật đang chạy nền (Auth 9099, Firestore 8080)
- Phát hiện và sửa một crash thật (`[core/duplicate-app]`) mà chỉ runtime thật mới lộ ra — không thể phát hiện qua `flutter analyze` hay code review tĩnh, đúng mục đích của spike này
- Thu được bằng chứng đầy đủ: `spike_run.log` chứa cả `[SPIKE] SQLITE PASS` và `[SPIKE] FIREBASE PASS`, screenshot xác nhận trực quan trùng khớp
- Dọn sạch tiến trình sau khi thu bằng chứng: `flutter run` và `firebase emulators:start` đều bị kill, không còn port `LISTENING` trên 9099/8080/4000
- `00-SPIKE-FINDINGS.md` ghi verdict `GO` với đầy đủ trích dẫn bằng chứng, bảng Requirement Coverage (FND-01/03/04), bảng Credential & Regression Hygiene

## Task Commits

Mỗi task được commit atomic:

1. **Task 1: Kiểm tra tĩnh hồi quy (FFI, credential hygiene, flutter analyze)** — không có thay đổi file (mọi kiểm tra pass ngay, không cần fix), không tạo commit riêng
2. **Task 2: Chạy spike thật + fix bug duplicate-app + thu bằng chứng** - `0984d0c` (fix)
3. **Task 3: Viết 00-SPIKE-FINDINGS.md verdict GO** - `12a1efe` (docs)

**Plan metadata:** (commit tiếp theo, xem cuối phiên)

## Files Created/Modified
- `spike_platform/lib/main.dart` - Bọc `Firebase.initializeApp()` trong try/catch, bắt riêng `FirebaseException(code: 'duplicate-app')`
- `.planning/phases/00-platform-spike/evidence/spike-screenshot.png` - Ảnh chụp `emulator-5554` lúc 10:44, hiển thị cả 2 dòng PASS trên UI
- `.planning/phases/00-platform-spike/00-SPIKE-FINDINGS.md` - Verdict GO, bảng Evidence/Requirement Coverage/Credential Hygiene
- `spike_platform/spike_run.log` - Log console đầy đủ (gitignored qua `*.log`, tồn tại trên đĩa làm bằng chứng nhưng không commit)

## Decisions Made
- **Bắt `FirebaseException(code: 'duplicate-app')` thay vì `Firebase.apps.isEmpty`:** Thử `isEmpty` trước nhưng không ngăn được crash vì `Firebase.apps` là cache phía Dart luôn bắt đầu rỗng, không phản ánh trạng thái native đã được Google Services Gradle plugin tự khởi tạo từ trước qua `ContentProvider`.
- **Dùng JBR (JDK 21) có sẵn của Android Studio cho `firebase-tools`:** Java mặc định trên PATH là Oracle Java 8, không đủ cho `firebase-tools` v15+ (yêu cầu JDK ≥ 21). Máy đã có JDK 21 đi kèm Android Studio nên dùng luôn, không cần cài phần mềm mới (không vi phạm exclusion "package install" của deviation rules vì đây không phải cài package, chỉ trỏ lại `JAVA_HOME`/`PATH` tới JDK có sẵn).
- **`flutter run -d emulator-5554` thay vì `-d android`:** Device id `android` không tồn tại trong Flutter CLI hiện tại; phải dùng đúng id lấy từ `flutter devices`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `[core/duplicate-app]` crash khi Firebase khởi tạo 2 lần**
- **Found during:** Task 2, lần chạy đầu tiên trên `emulator-5554`
- **Issue:** Google Services Gradle plugin (cấu hình từ Plan 00-01) tự động tạo `FirebaseApp` gốc `[DEFAULT]` từ `google-services.json` qua `ContentProvider` trước khi `main()` chạy. Gọi `Firebase.initializeApp(options: spikeFirebaseOptions)` lần nữa (từ Plan 00-02) ném `FirebaseException [core/duplicate-app]`, khiến app crash toàn bộ luồng test, cả 2 test không chạy được.
- **Fix:** Bọc lệnh gọi trong `try/catch`, bắt riêng mã lỗi `'duplicate-app'` và bỏ qua an toàn (native app đã cùng identity `demo-spike-project`); lỗi khác vẫn `rethrow`.
- **Files modified:** `spike_platform/lib/main.dart`
- **Verification:** Chạy lại → không còn exception; `spike_run.log` dòng 36 và 124 xác nhận cả 2 PASS; screenshot khớp; `flutter analyze` vẫn sạch sau fix.
- **Committed in:** `0984d0c`

**2. [Rule 3 - Blocking] `firebase emulators:start` fail vì Java 8 không đủ mới**
- **Found during:** Task 2, lần khởi động Firebase Emulator Suite đầu tiên
- **Issue:** `Error: firebase-tools no longer supports Java version before 21.` — Java mặc định trên PATH là `1.8.0_202`.
- **Fix:** Trỏ `JAVA_HOME`/`PATH` (dùng đường dẫn POSIX `/c/Program Files/...`, không phải `C:/Program Files/...` — dạng Windows chèn vào PATH của Git Bash không resolve đúng) tới JDK 21 có sẵn tại `C:\Program Files\Android\Android Studio\jbr`.
- **Files modified:** Không có (chỉ biến môi trường tiến trình chạy nền)
- **Verification:** `All emulators ready!` xuất hiện trong `firebase_emulator.log`, Auth 9099 + Firestore 8080 sẵn sàng.
- **Committed in:** Không áp dụng

**3. [Rule 3 - Blocking] Device id `android` không hợp lệ**
- **Found during:** Task 2, chạy đúng lệnh `flutter run -d android` như plan ghi
- **Issue:** `No supported devices found with name or id matching 'android'.`
- **Fix:** Đổi sang `flutter run -d emulator-5554 --no-pub` (device id thật lấy từ `flutter devices`).
- **Files modified:** Không có
- **Verification:** Build + install + chạy thành công trên `emulator-5554`
- **Committed in:** Không áp dụng

---

**Total deviations:** 3 auto-fixed (1 Rule 1 - bug, 2 Rule 3 - blocking)
**Impact on plan:** Cả 3 fix đều cần thiết để plan chạy được thật trên môi trường thật — không có scope creep, không thêm tính năng ngoài phạm vi. Fix #1 (duplicate-app) đặc biệt quan trọng: đây là loại bug chỉ runtime thật mới lộ ra, minh chứng đúng giá trị của spike thay vì chỉ `flutter analyze`.

## Issues Encountered

**Kiểm tra hồi quy FFI có "false positive" ban đầu:** `grep -rn "sqflite_common_ffi\|databaseFactoryFfi" spike_platform/` (theo đúng câu lệnh trong plan, không giới hạn thư mục) khớp 3 dòng bên trong `spike_platform/.dart_tool/` và `spike_platform/build/` — đây là cache nhị phân do compiler sinh ra (chứa metadata/tên định danh nội bộ của gói `sqflite`), cả hai thư mục đều bị `.gitignore` chặn hoàn toàn (`.dart_tool/`, `/build/`) và không phải source code do team viết. Đã xác nhận scoped-grep (loại trừ 2 thư mục cache) trả về rỗng — không phải regression thật. Ghi chú lại trong `00-SPIKE-FINDINGS.md` mục Credential Hygiene.

**Tiến trình node/java từ lần thử Firebase Emulator thất bại đầu tiên còn sót lại:** Lần đầu `firebase emulators:start` fail do Java 8 nhưng để lại 2 tiến trình `node.exe` orphan không tự thoát. Đã dừng thủ công (`Stop-Process`) trước khi thử lại lần 2 với JDK 21, tránh xung đột port khi thử lại.

## User Setup Required
Không cần — mọi fix đều dùng tài nguyên có sẵn trên máy (JDK 21 đi kèm Android Studio), không cần cài phần mềm mới hay biến môi trường thủ công.

## Next Phase Readiness

- 3/3 success criteria của ROADMAP Phase 0 đã được chứng minh bằng bằng chứng thật trên thiết bị Android thật + Firebase Emulator Suite thật — không chỉ dừng ở `flutter analyze`.
- `00-SPIKE-FINDINGS.md` ghi verdict `GO` rõ ràng, trích dẫn đầy đủ log + screenshot.
- **Pattern quan trọng mang sang Phase 1:** Khi Phase 1 tích hợp `google-services.json` thật (không phải dummy), rất có thể sẽ gặp lại đúng bug `[core/duplicate-app]` này — cần áp dụng lại pattern try/catch `FirebaseException(code: 'duplicate-app')` ngay từ đầu thay vì phải debug lại từ số 0.
- Không có blocker nào chặn Phase 1.

## Self-Check: PASSED

- FOUND: `spike_platform/lib/main.dart` (modified)
- FOUND: `.planning/phases/00-platform-spike/evidence/spike-screenshot.png`
- FOUND: `.planning/phases/00-platform-spike/00-SPIKE-FINDINGS.md`
- FOUND: `spike_platform/spike_run.log` (on disk, gitignored)
- FOUND: commit `0984d0c` in `git log`
- FOUND: commit `12a1efe` in `git log`

---
*Phase: 00-platform-spike*
*Completed: 2026-07-18*
