---
phase: 00-platform-spike
verified: 2026-07-18T23:00:00Z
status: passed
resolved: 2026-07-18T23:30:00Z
resolution: |
  Ban đầu gsd-verifier trả về `human_needed` với đúng một blocker: CR-01
  (useAuthEmulator không được await → bằng chứng Firebase PASS là race, không
  phải chứng minh tất định). Người dùng đã quyết định fix thay vì chấp nhận rủi
  ro. Blocker đã được gỡ bằng bằng chứng thực nghiệm, không phải bằng khẳng định:
    - `spike_platform/lib/main.dart:39` — nay `await` useAuthEmulator.
    - Chạy lại spike 3 lần độc lập trên emulator-5554, mỗi lần thoát sạch trước
      lần kế: cả 3 đều ra `[SPIKE] SQLITE PASS` + `[SPIKE] FIREBASE PASS`, không
      dòng FAIL nào. Log: spike_run_pass2_1.log / _2.log / _3.log (PID 11799,
      12000, 12153 — xác nhận là 3 tiến trình riêng biệt, không phải một log
      bị nhân bản).
    - Orchestrator đã tự grep lại cả 3 log để xác minh, không chỉ tin báo cáo agent.
  Human verification item #2 (AVD Google APIs) cũng đã pass — xác nhận bằng hai
  nguồn độc lập: `flutter devices` trả "sdk gphone16k" và `tag.id=google_apis`
  trong Pixel_6.avd/config.ini.
  Item #3 (team review CR-02/CR-04) vẫn mở trong 00-HUMAN-UAT.md — đây là việc
  đọc tài liệu của team, không phải cổng kỹ thuật, nên không chặn Phase 0.
  Trạng thái này do orchestrator cập nhật sau khi tự kiểm chứng, không phải do
  gsd-verifier chạy lại.
score: 3/3 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Đánh giá khả năng tin cậy của bằng chứng Firebase khi có race condition CR-01"
    expected: "useAuthEmulator() được await, hoặc team chấp nhận rủi ro race condition"
    why_human: "CR-01 trong code review chỉ ra race condition khi useAuthEmulator() không được await. Tuy test đã PASS trong lần chạy này, nhưng điều đó không chứng minh được nó sẽ PASS một cách xác định lần sau. Cần quyết định con người: (a) fix CR-01 và chạy lại, (b) chấp nhận rủi ro với warning, hay (c) từ chối tiếp tục cho tới khi fix được."
  - test: "Xác nhận môi trường Android emulator dùng Google APIs system image"
    expected: "AVD Manager hoặc adb shell getprop cho biết system image là Google APIs, không phải AOSP thuần"
    why_human: "Firestore Emulator yêu cầu Google Play Services; AOSP thuần không có, test sẽ fail. Screenshot cần được đối chiếu với Device Manager để xác nhận."
  - test: "Kiểm tra CR-02, CR-03, CR-04 từ code review và quyết định scope Phase 1"
    expected: "Team biết rõ mỗi CR-* là gì, tầm ảnh hưởng đến Phase 1, và cần fix hay chỉ warning"
    why_human: "CR-02 (setState không check mounted) sẽ bị chép sang Phase 1 nếu không cảnh báo. CR-03 (Firestore rules mở) là rủi ro bảo mật nếu deploy nhầm. CR-04 (gitignore không template) khiến team khác build không được. Cần human review tài liệu này."
---

# Phase 0: Platform Spike — Báo cáo Xác minh

**Phase Goal:** Chứng minh thực nghiệm trên Android emulator thật rằng stack bắt buộc (sqflite + Firebase Auth + Firestore) đã hoạt động.

**Verified:** 2026-07-18
**Status:** human_needed (Đạt 3/3 observable truths, nhưng cần human review CR-01 race condition)
**Score:** 3/3 must-haves verified

## Tóm tắt

Spike Platform đã chạy thành công trên Android emulator Google APIs, chứng minh được:
1. ✓ App khởi động không crash
2. ✓ sqflite round-trip ghi/đọc thành công
3. ✓ Firebase Auth + Firestore round-trip thành công

Bằng chứng đầy đủ được capture trong log (`spike_run.log`) và ảnh chụp (`evidence/spike-screenshot.png`). Cả 3 requirement FND-01, FND-03, FND-04 đã verify qua bằng chứng trên thiết bị thật.

**Tuy nhiên:** Code review (00-REVIEW.md) xác định 4 critical issues, trong đó CR-01 (race condition trên `useAuthEmulator()`) trực tiếp ảnh hưởng đến độ tin cậy của bằng chứng Firebase. Tuy test này lần này PASS, nhưng không đảm bảo nó sẽ PASS lần tiếp theo nếu race condition xảy ra.

**Kết luận:** Cần human review quyết định xem có nên (a) fix CR-01 trước Phase 1, (b) chấp nhận rủi ko với warning, hay (c) chạy lại test nhiều lần để chứng minh tính ổn định.

---

## Xác minh Observable Truths

### Truth 1: App khởi động trên Android emulator không crash

**Evidence:**
- Screenshot: `evidence/spike-screenshot.png` hiển thị app "Platform Spike" render đầy đủ giao diện
- AppBar title: "Platform Spike"
- 2 buttons: "Re-run SQLite Test", "Re-run Firebase Test"  
- 2 log lines: SQLite PASS và Firebase PASS hiển thị

**Status:** ✓ **VERIFIED**

---

### Truth 2: SQLite thuần mở database và round-trip ghi/đọc thành công trên Android

**Evidence:**
```
spike_run.log dòng 36:
I/flutter (11199): [SPIKE] SQLITE PASS: {id: 1, value: hello-from-android}
```

**Artifacts:**
- `spike_platform/lib/sqlite_service.dart` - Exports `testSqliteInsertAndRead()`
  - Gọi `getDatabasesPath()` → mở file database  
  - Ghi row: `{'value': 'hello-from-android'}`
  - Đọc lại toàn bộ table
  - Return chuỗi bắt đầu với `'SQLITE PASS: '` chứa kết quả

**Wiring:**
- `main.dart` import `sqlite_service` ✓
- `_runAllTests()` gọi `testSqliteInsertAndRead()` ✓
- Kết quả append vào `_log` và render trên UI ✓

**Status:** ✓ **VERIFIED**

---

### Truth 3: Firebase Auth + Firestore round-trip thành công qua Emulator

**Evidence:**
```
spike_run.log dòng 124:
I/flutter (11199): [SPIKE] FIREBASE PASS: {value: hello-firebase}
```

**Artifacts:**
- `spike_platform/lib/firebase_service.dart` - Exports `testFirebaseInitAuthFirestore()`
  - Khởi tạo credential test: `spike_test_user@example.com` / `SpikeTest123!`
  - Gọi `createUserWithEmailAndPassword()` (hoặc fallback `signInWithEmailAndPassword` nếu tài khoản tồn tại)
  - Ghi Firestore: `db.collection('spike_test').doc('spike_doc').set({'value': 'hello-firebase'})`
  - Đọc lại: `.get()`
  - Return chuỗi bắt đầu với `'FIREBASE PASS: '` chứa kết quả

**Wiring:**
- `main.dart` import `firebase_service` ✓
- `_runAllTests()` gọi `testFirebaseInitAuthFirestore()` ✓
- Kết quả append vào `_log` và render trên UI ✓

**Status:** ✓ **VERIFIED** (với caveat CR-01 — xem phần Human Verification)

---

## Xác minh Artifacts

| Artifact | Exists | Substantive | Wired | Status |
|----------|--------|-------------|-------|--------|
| `spike_platform/lib/sqlite_service.dart` | ✓ | ✓ try/catch PASS/FAIL | ✓ main.dart gọi | ✓ VERIFIED |
| `spike_platform/lib/firebase_service.dart` | ✓ | ✓ try/catch PASS/FAIL | ✓ main.dart gọi | ✓ VERIFIED |
| `spike_platform/lib/main.dart` | ✓ | ✓ Firebase init + UI | ✓ runApp root | ✓ VERIFIED |
| `spike_platform/lib/platform_config.dart` | ✓ | ✓ emulator host/port constants | ✓ main.dart import | ✓ VERIFIED |
| `spike_platform/lib/firebase_options_spike.dart` | ✓ | ✓ FirebaseOptions dummy | ✓ main.dart Firebase.initializeApp() | ✓ VERIFIED |
| `.planning/phases/00-platform-spike/00-SPIKE-FINDINGS.md` | ✓ | ✓ Verdict GO + tables | ✓ Links log + screenshot | ✓ VERIFIED |
| `.planning/phases/00-platform-spike/evidence/spike-screenshot.png` | ✓ | ✓ (non-trivial size) | N/A | ✓ VERIFIED |
| `spike_platform/spike_run.log` | ✓ | ✓ Contains [SPIKE] prefixes | N/A | ✓ VERIFIED |

---

## Xác minh Requirements Coverage

| Requirement | Source | Phase | Status | Bằng chứng |
|-------------|--------|-------|--------|-----------|
| **FND-01** | REQUIREMENTS.md | 00-platform-spike | ✓ PASS | App khởi động trên emulator, screenshot hiển thị "Platform Spike" render đầy đủ, không crash |
| **FND-03** | REQUIREMENTS.md | 00-platform-spike | ✓ PASS | `spike_run.log` line 36: `[SPIKE] SQLITE PASS: {id: 1, value: hello-from-android}` |
| **FND-04** | REQUIREMENTS.md | 00-platform-spike | ✓ PASS | `spike_run.log` line 124: `[SPIKE] FIREBASE PASS: {value: hello-firebase}` |
| **FND-02** | REQUIREMENTS.md (withdrawn 2026-07-18) | N/A | N/A | Withdrawn — Windows desktop target đã bị loại; xem REQUIREMENTS.md dòng 15/180 |

---

## Regression Checks

| Check | Lệnh | Expected | Result |
|-------|------|----------|--------|
| Không sqflite_common_ffi | `grep -rn "sqflite_common_ffi\|databaseFactoryFfi" spike_platform/lib/ spike_platform/pubspec.yaml` | Rỗng | ✓ Rỗng — PASS |
| Không API key thật (AIza*) | `grep -rn "AIza" spike_platform/lib/` | Rỗng | ✓ Rỗng — PASS |
| google-services.json gitignored | `git check-ignore spike_platform/android/app/google-services.json` | Exit code 0 | ✓ Exit 0 — PASS |
| flutter analyze | `cd spike_platform && flutter analyze` | No issues found | ✓ No issues — PASS |

---

## Code Review Findings (từ 00-REVIEW.md)

### Critical Issues

**CR-01: `useAuthEmulator()` không được `await` — Race Condition ⚠️ BLOCKER**

**File:** `spike_platform/lib/main.dart:34`

**Issue:** `FirebaseAuth.instance.useAuthEmulator(...)` trả về `Future<void>` nhưng được gọi mà không `await`. Có cửa sổ thời gian mà lệnh `createUserWithEmailAndPassword()` có thể phát đi TRƯỚC khi emulator kịp configure, làm request đi tới Firebase thật thay vì emulator.

**Current Code:**
```dart
// main.dart:34 - NOT awaited
FirebaseAuth.instance.useAuthEmulator(kAuthEmulatorHost, kAuthEmulatorPort);
```

**Impact:** Tuy test lần này PASS (may mắn không trúng race condition), nhưng không đảm bảo PASS lần tiếp theo. Verdict "GO" không hoàn toàn đáng tin vì dựa trên kết quả của một run duy nhất với race condition.

**Status:** ⚠️ **UNFIXED** — Cần human review quyết định xem có nên fix trước Phase 1 không

---

**CR-02: `setState()` sau `await` không check `mounted`**

Cả `_runAllTests()`, `_rerunSqliteTest()`, `_rerunFirebaseTest()` đều gọi `setState()` sau `await` mà không kiểm tra `mounted`. Nếu widget bị dispose giữa chừng (xoay màn hình, hot restart, widget test kết thúc), sẽ ném lỗi. Đây là pattern nguy hiểm sẽ bị chép sang Phase 1 nếu không cảnh báo.

**Status:** ⚠️ **WARNING** — Cần cảnh báo team, pattern này không nên copy sang Phase 1

---

**CR-03: Firestore rules mở toang nhưng deployable**

`firestore.rules` có `allow read, write: if true` đủ cho emulator, nhưng không có gì ngăn deploy vào project thật. `.firebaserc` đã có alias, `firebase.json` đã khai báo rules file. Chỉ cần một người đổi `.firebaserc` sang project thật rồi chạy `firebase deploy`, toàn bộ Firestore của nhóm (tài khoản, lớp học, điểm kiểm tra) sẽ mở công khai.

**Status:** ⚠️ **CRITICAL** — Cần bỏ đăng ký rules khỏi `firebase.json` hoặc khóa rules mặc định trước Phase 1

---

**CR-04: Spike không tái lập được trên máy khác**

`google-services.json` bị gitignore mà không có template hay hướng dẫn. Thành viên clone repo sạch **không thể build được**. README vẫn là template Flutter default.

**Status:** ⚠️ **WARNING** — Cần commit `google-services.json.example` hoặc viết README với hướng dẫn tái lập

---

### Warning Issues

**WR-01:** SQLite database handle rò rỉ khi error  
**WR-02:** Kiểm chứng SQLite cho kết quả giả (luôn return hàng lần chạy đầu tiên)  
**WR-03:** Kiểm chứng Firebase không assert nội dung; snapshot.data() có thể null  
**WR-04:** INTERNET permission chỉ có ở debug; release build sẽ fail  
**WR-05:** Widget test kích hoạt I/O thật và "pass" nhờ catch nuốt lỗi  

---

## Deviations from Plan (đã được auto-fix)

**1. sqflite ^2.4.2 thay vì ^2.4.3**
- Reason: Dart SDK 3.11.5 (bundled với Flutter 3.41.9) quá cũ cho `sqflite ^2.4.3`
- Status: ✓ Fixed, documented trong 00-01-SUMMARY.md

**2. minSdk 24 thay vì 23**
- Reason: Flutter MinSdkVersionMigration tự động ghi đè 23 về 24 mỗi lần build
- Status: ✓ Fixed, documented trong 00-01-SUMMARY.md

**3. Kotlin DSL (.kts) thay vì Groovy (.gradle)**
- Reason: flutter create scaffold mặc định trên Flutter 3.41.9 là .kts
- Status: ✓ Fixed, áp dụng tất cả syntax tương đương

**4. FirebaseException duplicate-app**
- Reason: Google Services Gradle plugin auto-init native app từ google-services.json
- Status: ✓ Fixed trong 00-03, bọc Firebase.initializeApp() trong try/catch

---

## Decisions Made

| Decision | Reason | Impact |
|----------|--------|--------|
| Firebase Emulator chạy empty data (không import/export) | Phase 0 chỉ chứng minh hoạt động, không seed baseline data | Phase 1 sẽ decide baseline data nếu cần |
| Dùng platform-conditional constants (10.0.2.2 cho Android) | Android emulator không thấy localhost; loopback 10.0.2.2 là alias đặc biệt | Hợp lệ cho emulator, không chạy được trên device thật |

---

## Anti-Patterns Scan

Spike là code throwaway, nên bỏ qua "production" anti-patterns (TODO boilerplate, hardcode string, release signing with debug key, etc.). Các issue được ghi nhận có chủ đích không tính là lỗi.

Anti-pattern summary:
- ✓ Debt markers: Không có TBD/FIXME/XXX
- ⚠️ Empty implementations: Service functions có try/catch fallback, không "return null" trơn trơn
- ⚠️ Unused imports: Minimal, acceptable cho spike

---

## Human Verification Required

### 1. Kiểm tra CR-01 Race Condition

**Test:** Đọc CR-01 trong 00-REVIEW.md và quyết định xem có cần fix trước Phase 1

**Expected:** Team chọn một trong ba phương án:
- **(A)** Fix: Await `useAuthEmulator()`, run lại test, chứng minh PASS ổn định
- **(B)** Acknowledge: Chấp nhận rủi ro race condition với warning rõ ràng cho Phase 1
- **(C)** Reject: Yêu cầu fix CR-01 trước khi Phase 1 được phép bắt đầu

**Why human:** Quyết định con người về risk tolerance — code chạy lần này nhưng không đảm bảo xác định lần sau.

---

### 2. Xác nhận AVD dùng Google APIs

**Test:** Mở Android Studio Device Manager, kiểm tra AVD `Pixel_6` (hoặc emulator đã dùng)

**Expected:** Column "Target" / "Services" hiển thị "Google APIs" hoặc "Google Play" (không phải "AOSP thuần")

**Why human:** Firestore Emulator yêu cầu Google Play Services; AOSP thuần không có, test sẽ fail.

---

### 3. Review Code Review Findings

**Test:** Team lead đọc toàn bộ 00-REVIEW.md, hiểu từng CR-* / WR-*

**Expected:** 
- Biết rõ mỗi issue ảnh hưởng gì đến Phase 1
- Quyết định: nào cần fix ngay, nào chỉ warning, nào là design decision
- CR-03 (Firestore rules) PHẢI được giải quyết trước Phase 1 vì bảo mật

**Why human:** Code review chứa các pattern nguy hiểm sẽ bị chép sang Phase 1 nếu không cảnh báo đúng cách.

---

## Readiness for Phase 1

**Blocker:** CR-01 race condition — cần human approval xem có ổn định hay không

**Action Items for Phase 1:**
1. ✓ Use `FirebaseException(code: 'duplicate-app')` pattern — đã test thành công ở Phase 0
2. ⚠️ Expect `sqflite ^2.4.2`, not `^2.4.3` — CLAUDE.md cần update hoặc Foundation Phase cần note này
3. ⚠️ Expect `minSdk = 24`, not 23 — Flutter auto-migration đã established pattern này
4. ⚠️ Watch CR-02 pattern (setState without mounted) — rất dễ bị chép sang Phase 1, cần linting rule
5. 🛑 **Do NOT copy Firestore rules từ spike** — CR-03 bảo mật issue, Phase 1 thiết kế rules từ đầu

---

## Summary

**Goal Achievement:** ✓ Achieved
- Spike ran on real Android emulator (screenshot + log evidence)
- SQLite round-trip verified (SQLITE PASS line)
- Firebase Auth/Firestore round-trip verified (FIREBASE PASS line)
- All 3 FND requirements covered by evidence on real device

**Implementation Quality:** ⚠️ Issues Found
- CR-01: Race condition makes Firebase proof non-deterministic
- CR-02: setState pattern copies to Phase 1 need guidance
- CR-03: Firestore rules deployability is security risk
- CR-04: Spike not reproducible on other machines

**Verdict:** Phase 0 goal technically achieved, but **human review required** on CR-01 race condition before Phase 1 can confidently proceed on this foundation.

---

*Verified: 2026-07-18*
*Verifier: Claude (gsd-verifier)*
*Method: Goal-backward verification against artifacts + code review findings*
