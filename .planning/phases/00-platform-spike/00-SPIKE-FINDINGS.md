---
phase: 00-platform-spike
plan: 03
type: findings
created: 2026-07-18
---

# Phase 0 Platform Spike — Findings

## Verdict: GO

Spike đã chạy thật trên Android emulator Google APIs system image, kết nối với Firebase Emulator Suite đang chạy nền, và cả 2 phép thử (`sqflite` round-trip + Firebase Auth/Firestore round-trip) đều PASS — có bằng chứng console log và screenshot đính kèm. Firebase Emulator Suite và `flutter run` đã được tắt sạch sau khi thu bằng chứng. Không còn dấu vết `sqflite_common_ffi`/`databaseFactoryFfi`/API key thật trong source code.

**Phase 1 được phép bắt đầu.**

---

## Evidence

| Nguồn | Nội dung |
|-------|----------|
| `spike_platform/spike_run.log` (dòng 36) | `I/flutter (11199): [SPIKE] SQLITE PASS: {id: 1, value: hello-from-android}` |
| `spike_platform/spike_run.log` (dòng 124) | `I/flutter (11199): [SPIKE] FIREBASE PASS: {value: hello-firebase}` |
| `evidence/spike-screenshot.png` | Ảnh chụp emulator-5554 lúc 10:44, app "Platform Spike" đang chạy, hiển thị đúng 2 dòng `SQLITE PASS: {id: 1, value: hello-from-android}` và `FIREBASE PASS: {value: hello-firebase}` trên UI — khớp 100% với log |

**Môi trường xác nhận:**
- Emulator: `emulator-5554`, AVD `Pixel_6`, `tag.id=google_apis` (đọc trực tiếp từ `$USERPROFILE/.android/avd/Pixel_6.avd/config.ini`) — xác nhận là Google APIs system image, không phải AOSP thuần, nên Firebase Auth chạy được.
- Firebase Emulator Suite: `firebase emulators:start --only auth,firestore --project demo-spike-project` — log xác nhận `All emulators ready!`, Auth `127.0.0.1:9099`, Firestore `127.0.0.1:8080`.

---

## Requirement Coverage

| Requirement | Pass/Fail | Bằng chứng |
|-------------|-----------|------------|
| FND-01 (App khởi động trên Android emulator không crash) | Pass | Visual: `evidence/spike-screenshot.png` hiển thị app "Platform Spike" render đầy đủ UI (2 nút re-run + 2 dòng log), không có màn hình crash/ANR. `spike_run.log` không có dòng `FlutterError`/`Fatal Exception` sau khi fix (xem mục Deviations). |
| FND-03 (`sqflite` thuần round-trip trên Android) | Pass | `spike_run.log` dòng 36: `[SPIKE] SQLITE PASS: {id: 1, value: hello-from-android}` |
| FND-04 (Firebase Auth + Firestore round-trip qua Emulator Suite) | Pass | `spike_run.log` dòng 124: `[SPIKE] FIREBASE PASS: {value: hello-firebase}` |

---

## Credential & Regression Hygiene (Task 1)

| Kiểm tra | Lệnh | Kết quả |
|----------|------|---------|
| Không còn `sqflite_common_ffi`/`databaseFactoryFfi` trong source | `grep -rn "sqflite_common_ffi\|databaseFactoryFfi" spike_platform/lib/ spike_platform/pubspec.yaml` | Rỗng — pass. (Lưu ý: `grep -rn ... spike_platform/` không giới hạn thư mục có khớp 3 dòng trong `spike_platform/.dart_tool/` và `spike_platform/build/` — đây là cache nhị phân do toolchain sinh ra, cả hai thư mục đều bị `.gitignore` chặn (`/build/`, `.dart_tool/`) và không phải source do team viết; không tính là regression.) |
| Không có API key thật (`AIza*`) trong `lib/` | `grep -rn "AIza" spike_platform/lib/` | Rỗng — pass |
| `google-services.json` vẫn gitignored | `git check-ignore spike_platform/android/app/google-services.json` | Exit code `0` — pass |
| `flutter analyze` sạch | `cd spike_platform && flutter analyze` | `No issues found! (ran in 4.4s)` — pass (chạy lại sau khi fix Task 2, vẫn sạch) |

---

## Deviations from Plan (Auto-fixed)

**1. [Rule 1 - Bug] `[core/duplicate-app]` crash khi Firebase khởi tạo 2 lần**
- **Found during:** Task 2, lần chạy `flutter run -d emulator-5554` đầu tiên
- **Issue:** Google Services Gradle plugin (`com.google.gms.google-services`, cấu hình ở Plan 00-01) tự động khởi tạo một `FirebaseApp` gốc `[DEFAULT]` từ `android/app/google-services.json` qua `ContentProvider` trước khi `main()` của Dart chạy. `main.dart` (Plan 00-02) sau đó gọi `Firebase.initializeApp(options: spikeFirebaseOptions)` một lần nữa → ném `FirebaseException` `[core/duplicate-app] A Firebase App named "[DEFAULT]" already exists`, khiến app crash ngay khi mở, cả 2 test đều không chạy được.
- **Fix:** Bọc `Firebase.initializeApp(...)` trong `try/catch`, bắt riêng `FirebaseException` có `code == 'duplicate-app'` và bỏ qua (an toàn vì app native đã dùng cùng identity `demo-spike-project` với `spikeFirebaseOptions`); các lỗi khác vẫn `rethrow`. (Thử phương án `Firebase.apps.isEmpty` trước nhưng không hiệu quả — `Firebase.apps` là cache phía Dart, luôn bắt đầu rỗng bất kể trạng thái native, nên không phát hiện được app đã tồn tại native-side.)
- **Files modified:** `spike_platform/lib/main.dart`
- **Verification:** Chạy lại `flutter run -d emulator-5554` sau fix → không còn exception, cả `[SPIKE] SQLITE PASS` và `[SPIKE] FIREBASE PASS` xuất hiện trong log và trên UI (screenshot). `flutter analyze` vẫn sạch.
- **Committed in:** `0984d0c`

**2. [Rule 3 - Blocking] `firebase emulators:start` fail vì Java 8 không đủ mới**
- **Found during:** Task 2, lần khởi động Firebase Emulator Suite đầu tiên
- **Issue:** Java mặc định trên PATH (Oracle `javapath`) là `1.8.0_202`; `firebase-tools` (Firestore emulator) yêu cầu JDK ≥ 21. Lỗi: `firebase-tools no longer supports Java version before 21. Please install a JDK at version 21 or above to get a compatible runtime.`
- **Fix:** Máy đã có sẵn JDK 21 đi kèm Android Studio (`C:\Program Files\Android\Android Studio\jbr`, OpenJDK 21.0.10) — không cần cài thêm gì. Chạy `firebase emulators:start` với `JAVA_HOME`/`PATH` trỏ vào JBR đó (dùng đường dẫn kiểu POSIX `/c/Program Files/...` trong Git Bash — đường dẫn kiểu Windows `C:/Program Files/...` chèn vào biến `PATH` không được bash resolve đúng).
- **Files modified:** Không có (chỉ là biến môi trường của tiến trình chạy nền, không cần thay đổi code/config)
- **Verification:** `firebase emulators:start --only auth,firestore --project demo-spike-project` in ra `All emulators ready!`, Auth `127.0.0.1:9099`, Firestore `127.0.0.1:8080`
- **Committed in:** Không áp dụng (không có thay đổi file để commit)

**3. [Rule 3 - Blocking] Device id `android` không khớp thiết bị nào**
- **Found during:** Task 2, lần chạy `flutter run -d android` đầu tiên theo đúng câu lệnh trong plan
- **Issue:** `flutter run -d android` báo `No supported devices found with name or id matching 'android'.` — thiết bị thật đang chạy có id là `emulator-5554`, không phải chuỗi `android`.
- **Fix:** Dùng `flutter run -d emulator-5554 --no-pub` (device id chính xác lấy từ `flutter devices`) thay vì `-d android`.
- **Files modified:** Không có (chỉ thay đổi lệnh chạy)
- **Verification:** Lệnh chạy thành công, build APK và cài lên `emulator-5554`
- **Committed in:** Không áp dụng

**Total deviations:** 3 auto-fixed (1 Rule 1 - bug, 2 Rule 3 - blocking). Không có deviation nào cần Rule 4 (không có thay đổi kiến trúc).

---

## Process Cleanup (T-0-05 mitigation)

- `flutter run` process tree (cmd.exe wrapper + dart.exe + dartvm.exe) đã bị dừng qua `taskkill`/`Stop-Process` sau khi thu bằng chứng.
- `firebase emulators:start` process tree (sh.exe wrapper → node.exe → java.exe Firestore emulator) đã bị dừng qua `taskkill /T /F`.
- `netstat -ano | grep LISTENING | grep -E ":9099|:8080|:4000"` trả về rỗng — xác nhận không còn tiến trình nào đang lắng nghe (LISTEN) trên các port đó.
- Lưu ý: `netstat -ano` (không lọc LISTENING) vẫn hiện vài dòng `FIN_WAIT_2`/`CLOSE_WAIT` liên quan tới port 9099 trong vài giây sau khi kill — đây là các socket đang trong quá trình đóng TCP bình thường của hệ điều hành (4-way handshake), không phải tiến trình đang hoạt động; không có `LISTENING` nghĩa là port đã thực sự được giải phóng cho lần bind kế tiếp.

---

## Next Phase Readiness

Cả 3 success criteria của ROADMAP Phase 0 đã được chứng minh bằng bằng chứng thật (không chỉ code review):
1. Flutter + Android Studio build và chạy được trên Android emulator thật.
2. `sqflite` thuần (không FFI) round-trip insert/read thành công trên Android thật.
3. Firebase Auth + Firestore round-trip thành công qua Firebase Emulator Suite từ app Android thật.

Phase 1 (shared foundation) có đủ căn cứ kỹ thuật để bắt đầu. Lưu ý mang sang Phase 1:
- `sqflite` phải pin `^2.4.2` (không phải `^2.4.3` như CLAUDE.md) do giới hạn Dart SDK của toolchain hiện tại.
- `minSdk = 24` (không phải 23).
- Khi Phase 1 tích hợp Firebase thật (không phải dummy config), cần áp dụng lại pattern bắt `FirebaseException` `duplicate-app` nếu `google-services.json` thật cũng kích hoạt auto-init native (rất có thể sẽ xảy ra tương tự).
