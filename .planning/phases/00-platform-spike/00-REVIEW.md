---
phase: 00-platform-spike
reviewed: 2026-07-18T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - spike_platform/lib/main.dart
  - spike_platform/lib/sqlite_service.dart
  - spike_platform/lib/firebase_service.dart
  - spike_platform/lib/platform_config.dart
  - spike_platform/lib/firebase_options_spike.dart
  - spike_platform/test/widget_test.dart
  - spike_platform/pubspec.yaml
  - spike_platform/firebase.json
  - spike_platform/firestore.rules
  - spike_platform/.gitignore
  - spike_platform/android/app/build.gradle.kts
  - spike_platform/android/settings.gradle.kts
  - spike_platform/android/app/src/debug/AndroidManifest.xml
findings:
  critical: 4
  warning: 5
  info: 4
  total: 13
status: issues_found
---

# Phase 0: Báo cáo Code Review

**Reviewed:** 2026-07-18
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Spike `spike_platform/` là code throwaway, nên review này đã bỏ qua toàn bộ nhóm vấn đề "production" (thiếu Riverpod, thiếu layering, thiếu i18n, chuỗi hardcode, release signing bằng debug key, TODO boilerplate của Flutter template). Các sai lệch đã được ghi nhận có chủ đích (`sqflite: ^2.4.2`, `minSdk = 24`, `google-services.json` dummy, catch `duplicate-app`) cũng không bị tính là lỗi.

Về mặt vệ sinh bí mật, spike làm **đúng**: `firebase_options_spike.dart` chỉ chứa giá trị giả (`demo-api-key-not-a-real-key`, project number toàn số 0), `google-services.json` đang bị `.gitignore` chặn và `git ls-files` xác nhận nó **không** nằm trong index. Không có credential thật nào bị commit.

Tuy nhiên, mục đích duy nhất của spike này là **tạo ra bằng chứng thực nghiệm đáng tin cậy** rằng sqflite + Firebase chạy được trên Android emulator, và chính điểm đó lại là chỗ yếu nhất. Bốn vấn đề Critical đều tấn công vào độ tin cậy của bằng chứng hoặc vào nguy cơ pattern xấu bị chép sang Phase 1:

- một race condition khiến verdict Firebase có thể sai ngẫu nhiên,
- `setState` sau `await` không kiểm tra `mounted` (pattern chắc chắn sẽ bị chép sang Phase 1),
- ruleset Firestore mở toang lại **deployable được** trong khi cả nhóm 5 người dùng chung một Firebase project,
- và spike không thể tái lập trên máy thành viên khác vì file bắt buộc để build đã bị gitignore mà không có template hay hướng dẫn.

## Critical Issues

### CR-01: `useAuthEmulator()` không được `await` — race condition khiến verdict Firebase không đáng tin

**File:** `spike_platform/lib/main.dart:34`

**Issue:** `FirebaseAuth.instance.useAuthEmulator()` trả về `Future<void>` (đã xác nhận trong `firebase_auth-*/lib/src/firebase_auth.dart:92` — `Future<void> useAuthEmulator(String host, int port, ...)`), nhưng ở đây nó bị gọi mà không `await`. Ngay sau đó `runApp()` chạy, `SpikeHomePage.initState()` kích hoạt `_runAllTests()`, và `testFirebaseInitAuthFirestore()` gọi `createUserWithEmailAndPassword()`.

Vì việc trỏ Auth về emulator là một platform-channel call bất đồng bộ, có một cửa sổ thời gian trong đó lệnh `createUser` có thể được phát đi **trước khi** cấu hình emulator kịp áp dụng. Khi trúng cửa sổ đó, request sẽ đi tới endpoint Firebase thật với `apiKey: 'demo-api-key-not-a-real-key'` và thất bại. Kết quả: spike in ra `FIREBASE FAIL` một cách ngẫu nhiên, và người chạy sẽ kết luận sai rằng Firebase không hoạt động trên Android — đúng thứ mà Phase 0 phải trả lời dứt khoát.

Lint không bắt được lỗi này vì `unawaited_futures` không nằm trong bộ mặc định của `flutter_lints` (xem `analysis_options.yaml`).

Lưu ý: `useFirestoreEmulator()` là hàm đồng bộ (trả `void`) nên dòng 35 không dính lỗi này.

**Fix:**
```dart
// main.dart
await FirebaseAuth.instance.useAuthEmulator(
  kAuthEmulatorHost,
  kAuthEmulatorPort,
);
FirebaseFirestore.instance.useFirestoreEmulator(
  kFirestoreEmulatorHost,
  kFirestoreEmulatorPort,
);

runApp(const SpikeApp());
```

### CR-02: `setState()` sau `await` không kiểm tra `mounted` — crash và làm widget test không đáng tin

**File:** `spike_platform/lib/main.dart:75`, `main.dart:80`, `main.dart:87`, `main.dart:94`

**Issue:** Cả bốn lời gọi `setState()` đều nằm sau một `await`, nhưng không chỗ nào kiểm tra `mounted`. Nếu widget bị dispose trong lúc `testSqliteInsertAndRead()` hoặc `testFirebaseInitAuthFirestore()` đang chạy (xoay màn hình, hot restart, back nhanh, hoặc widget test kết thúc), `setState()` sẽ ném `FlutterError: setState() called after dispose()`.

Đây không phải rủi ro lý thuyết: `test/widget_test.dart` chính là nơi kích hoạt nó. `tester.pumpWidget(const SpikeApp())` chạy `initState` → `_runAllTests()`, test assert xong rồi kết thúc và dispose widget, trong khi hai future kia vẫn đang chạy và sẽ gọi `setState()` trên một `State` đã chết.

Đây là loại pattern nguy hiểm nhất trong toàn bộ spike vì nó gần như chắc chắn sẽ được chép nguyên si sang Phase 1, nơi mọi màn hình đều có async load.

**Fix:**
```dart
Future<void> _runAllTests() async {
  final sqliteResult = await testSqliteInsertAndRead();
  debugPrint('[SPIKE] $sqliteResult');
  if (!mounted) return;
  setState(() => _log.add(sqliteResult));

  final firebaseResult = await testFirebaseInitAuthFirestore();
  debugPrint('[SPIKE] $firebaseResult');
  if (!mounted) return;
  setState(() => _log.add(firebaseResult));
}
```
Áp dụng cùng khuôn mẫu cho `_rerunSqliteTest()` và `_rerunFirebaseTest()`.

### CR-03: Firestore rules mở toang nhưng vẫn deployable — nguy cơ copy-forward vào project Firebase dùng chung

**File:** `spike_platform/firestore.rules:7-9`, `spike_platform/firebase.json:2-4`, `spike_platform/.firebaserc`

**Issue:** `allow read, write: if true` cho `/{document=**}` là hợp lý cho emulator, nhưng nó **không bị giới hạn ở emulator bằng bất kỳ cơ chế kỹ thuật nào** — chỉ bằng một comment. Cấu hình xung quanh biến nó thành một ruleset sẵn sàng deploy:

- `firebase.json` đăng ký `"firestore": { "rules": "firestore.rules" }`, tức `firebase deploy --only firestore:rules` sẽ nhận file này.
- `.firebaserc` đã có sẵn alias `default`, nên lệnh deploy không cần thêm tham số nào.

Hiện tại `default` trỏ tới `demo-spike-project` (không tồn tại) nên deploy sẽ fail — đó là tấm chắn duy nhất, và nó là một chuỗi ký tự có thể bị sửa trong 5 giây. Theo CLAUDE.md, **cả 5 thành viên dùng chung một Firebase project free tier**. Chỉ cần một người đổi `.firebaserc` sang project thật (một thao tác hoàn toàn tự nhiên khi bắt đầu Phase 1) rồi chạy `firebase deploy`, toàn bộ Firestore của nhóm — tài khoản, lớp học, điểm kiểm tra của học sinh — sẽ mở công khai cho mọi client có API key.

Review context đã nêu rõ: rules không an toàn nếu bị chép sang phía trước cần được flag. Đây đúng là trường hợp đó.

**Fix:** Ưu tiên cắt hẳn đường deploy thay vì chỉ dựa vào comment. Firestore Security Rules **không** có biến nào cho phép kiểm tra project id trong `request`, nên không thể tự khoá ruleset vào đúng project demo — cách phòng thủ khả thi là loại bỏ khả năng deploy.

Phương án khuyến nghị: bỏ đăng ký ruleset khỏi `firebase.json` để `firebase deploy` không còn đối tượng nào để đẩy đi. Emulator vẫn chạy bình thường (khi không khai báo rules, Firestore Emulator dùng chế độ mở mặc định của nó):
```json
{
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "ui": { "enabled": true, "port": 4000 }
  }
}
```
Sau đó xoá `firestore.rules` và `.firebaserc` khỏi git vì không còn được tham chiếu.

Nếu nhóm muốn giữ `firestore.rules` như tài liệu tham khảo cho Phase 1, hãy để nó ở trạng thái **đóng mặc định** kèm cảnh báo, sao cho tình huống xấu nhất (deploy nhầm) là từ chối truy cập chứ không phải mở toang — nhưng lưu ý Emulator vẫn thực thi rules, nên phải bỏ đăng ký nó trong `firebase.json` thì spike mới chạy được:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // CẢNH BÁO: file tham khảo cho Phase 1, KHÔNG được đăng ký trong
    // firebase.json và TUYỆT ĐỐI không deploy vào project dùng chung.
    // Mặc định đóng: rules thật sẽ được thiết kế ở Phase 1.
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### CR-04: Spike không tái lập được trên máy khác — `google-services.json` bị gitignore mà không có template, README vẫn là boilerplate

**File:** `spike_platform/.gitignore:47-48`, `spike_platform/README.md`

**Issue:** Deliverable của Phase 0 là bằng chứng có thể tái lập. Hiện tại một thành viên clone repo sạch **không thể build được**: plugin `com.google.gms.google-services` (khai báo ở `android/app/build.gradle.kts:6`) fail cứng lúc configure với lỗi `File google-services.json is missing` khi không tìm thấy file, và file đó đã bị `.gitignore` dòng 48 chặn (đã xác nhận bằng `git check-ignore`).

Đồng thời không có gì bù lại khoảng trống này:
- Không có `google-services.json.example` / `.template` nào được commit.
- `README.md` vẫn nguyên si template Flutter ("A new Flutter project.") — không hướng dẫn tạo lại file, không nói phải chạy `firebase emulators:start` trước, không nói cần chạy trên Android emulator chứ không phải thiết bị thật (vì `10.0.2.2`).

Thêm nữa, lý do ghi trong `.gitignore` là **sai sự thật** với file này: comment nói "contains project-linked identifiers", nhưng nội dung thực tế toàn giá trị dummy (`project_number: "000000000000"`, `api_key.current_key: "no-real-key-emulator-only-dummy"`). Không có bí mật nào để bảo vệ ở đây — cái giá phải trả (build hỏng cho cả nhóm) là hoàn toàn vô ích.

**Fix:** Chọn một trong hai, ưu tiên cách 1:

1. Commit thẳng file dummy này (nó không chứa credential nào), và giới hạn rule gitignore cho project thật ở Phase 1:
```gitignore
# Firebase config của project THẬT — không commit.
# Ngoại lệ: file dummy emulator-only của spike được commit có chủ đích
# để mọi thành viên build lại được (không chứa credential thật).
android/app/google-services.json
!android/app/google-services.json
```
2. Hoặc commit `android/app/google-services.json.example` và viết lại `README.md` với các bước tái lập: copy file example → `google-services.json`, `firebase emulators:start`, `flutter run -d emulator-5554`, kết quả kỳ vọng `SQLITE PASS` / `FIREBASE PASS`.

## Warnings

### WR-01: Rò rỉ database handle khi thao tác SQLite thất bại

**File:** `spike_platform/lib/sqlite_service.dart:14-32`

**Issue:** `db.close()` (dòng 27) chỉ nằm trên happy path. Nếu `db.insert()` (dòng 24) hoặc `db.query()` (dòng 26) ném lỗi, luồng nhảy thẳng xuống `catch` ở dòng 30 và database **không bao giờ được đóng**. Người dùng bấm nút "Re-run SQLite Test" sẽ mở lại cùng đường dẫn đó, tích luỹ thêm handle mỗi lần lỗi. Đây cũng là pattern quản lý tài nguyên sẽ bị chép sang lớp DAO của Phase 1.

**Fix:**
```dart
Database? db;
try {
  final databasesPath = await getDatabasesPath();
  db = await openDatabase(/* ... */);
  await db.insert('spike_test', {'value': 'hello-from-android'});
  final rows = await db.query('spike_test');
  return 'SQLITE PASS: ${rows.first}';
} catch (e) {
  return 'SQLITE FAIL: $e';
} finally {
  await db?.close();
}
```

### WR-02: Kiểm chứng SQLite cho kết quả giả — `rows.first` luôn trả về hàng của lần chạy đầu tiên

**File:** `spike_platform/lib/sqlite_service.dart:24-29`

**Issue:** Hàm insert một hàng mới mỗi lần chạy (id tự tăng), nhưng lại report `rows.first` — tức luôn là hàng `id = 1` từ lần chạy **đầu tiên**, không phải hàng vừa ghi. `spike.db` là file bền vững giữa các lần chạy app, nên từ lần thứ hai trở đi, mọi verdict `SQLITE PASS` đều đang hiển thị dữ liệu cũ.

Hệ quả: nếu insert im lặng không ghi được gì, hàm vẫn in ra `SQLITE PASS` kèm hàng cũ. Nút "Re-run SQLite Test" — thứ tồn tại chính để kiểm chứng lặp lại — do đó không chứng minh được gì cả. Với một artifact mà giá trị duy nhất là bằng chứng thực nghiệm, đây là false positive nghiêm trọng.

**Fix:** Ghi giá trị duy nhất mỗi lần chạy rồi đọc lại đúng giá trị đó và so sánh:
```dart
final marker = 'hello-from-android-${DateTime.now().microsecondsSinceEpoch}';
final id = await db.insert('spike_test', {'value': marker});

final rows = await db.query('spike_test', where: 'id = ?', whereArgs: [id]);
if (rows.length != 1 || rows.first['value'] != marker) {
  return 'SQLITE FAIL: round-trip mismatch — ghi "$marker", đọc lại ${rows.isEmpty ? "(rỗng)" : rows.first}';
}
return 'SQLITE PASS: $marker (id=$id)';
```

### WR-03: Kiểm chứng Firebase không assert nội dung đọc lại; `snapshot.data()` có thể null

**File:** `spike_platform/lib/firebase_service.dart:34-42`

**Issue:** Cùng loại lỗi với WR-02. Hàm `set()` rồi `get()` nhưng không hề so sánh giá trị đọc lại với giá trị đã ghi — nó chỉ in ra `snapshot.data()`. Nếu document không tồn tại, `snapshot.data()` trả `null` và hàm vẫn báo `FIREBASE PASS: null`, tức verdict PASS trong khi round-trip đã thất bại.

Ngoài ra `catch (e)` ở dòng 41 bắt mọi thứ, kể cả `NoSuchMethodError` hay `TypeError` do lỗi lập trình, rồi bọc chúng thành "FIREBASE FAIL" — làm người chạy tưởng là vấn đề nền tảng trong khi thực ra là bug trong chính spike.

**Fix:**
```dart
const marker = 'hello-firebase';
await docRef.set({'value': marker});
final snapshot = await docRef.get();

final data = snapshot.data();
if (!snapshot.exists || data == null || data['value'] != marker) {
  return 'FIREBASE FAIL: round-trip mismatch — ghi "$marker", đọc lại $data';
}
return 'FIREBASE PASS: $data';
```

### WR-04: Quyền INTERNET và cleartext chỉ có ở debug — build release/profile cho verdict FAIL sai

**File:** `spike_platform/android/app/src/debug/AndroidManifest.xml:6,13`, `spike_platform/android/app/src/main/AndroidManifest.xml`, `spike_platform/android/app/build.gradle.kts:42-46`

**Issue:** Việc giới hạn `usesCleartextTraffic="true"` ở debug manifest là **đúng và nên giữ**. Vấn đề nằm ở chỗ khác: `android.permission.INTERNET` cũng chỉ được khai báo ở `src/debug/` và `src/profile/`, hoàn toàn không có trong `src/main/AndroidManifest.xml`. Trong khi đó `build.gradle.kts:45` cố ý cấu hình release signing bằng debug key "so `flutter run --release` works" — tức chủ động mời người dùng chạy release build.

Nếu một thành viên xác minh spike bằng `flutter run --release` hoặc `--profile`, app sẽ không có quyền mạng (release) và không được phép cleartext tới `10.0.2.2` (cả release lẫn profile), nên Firebase chắc chắn fail. Họ sẽ ghi nhận "Firebase không chạy được trên Android" — kết luận sai, đúng vào câu hỏi Phase 0 cần trả lời.

**Fix:** Đưa `INTERNET` (permission vô hại, mọi app mạng đều cần) vào manifest chính, và ghi rõ trong README rằng spike **chỉ** verify được ở chế độ debug:
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application ...>
```
Giữ nguyên `usesCleartextTraffic` chỉ ở `src/debug/`, và thêm ghi chú vào README: "Chỉ chạy `flutter run` (debug). Release/profile build cố tình không cho cleartext nên không kết nối được emulator."

### WR-05: Widget test kích hoạt I/O thật và chỉ "pass" nhờ catch nuốt lỗi

**File:** `spike_platform/test/widget_test.dart:14`

**Issue:** `pumpWidget(const SpikeApp())` chạy `initState` → `_runAllTests()`, kéo theo `getDatabasesPath()` (platform channel của sqflite) và `FirebaseAuth.instance` (Firebase chưa hề được initialize trong môi trường test). Cả hai đều ném lỗi, nhưng bị `catch (e)` ở `sqlite_service.dart:30` và `firebase_service.dart:41` nuốt gọn thành chuỗi "FAIL", nên test không đỏ.

Test vì thế đang phụ thuộc vào side-effect ngoài ý muốn: nó pass chỉ vì phần error handling đủ rộng để che, chứ không phải vì code đúng. Kết hợp với CR-02, các future này còn gọi `setState()` sau khi widget đã bị dispose. Đây là test dễ vỡ và có thể ném lỗi lạ khi ai đó thu hẹp phạm vi `catch` ở WR-03.

**Fix:** Tách phần chạy test tự động ra khỏi `initState` để widget có thể render thuần tuý, ví dụ qua một cờ constructor:
```dart
class SpikeHomePage extends StatefulWidget {
  const SpikeHomePage({super.key, this.autoRun = true});
  final bool autoRun;
  // ...
}

// trong _SpikeHomePageState.initState():
if (widget.autoRun) _runAllTests();
```
rồi trong test dựng cây widget với `autoRun: false`. Nếu muốn giữ nguyên `SpikeApp`, ít nhất hãy dựng trực tiếp `SpikeHomePage(autoRun: false)` trong `MaterialApp` thay vì dựng cả app.

## Info

### IN-01: Mutate `_log` bên ngoài `setState`, rồi gọi `setState(() {})` rỗng

**File:** `spike_platform/lib/main.dart:73-75`, `78-80`, `85-87`, `92-94`

**Issue:** Ở cả bốn chỗ, `_log.add(...)` được thực hiện trước, sau đó `setState(() {})` chạy với body rỗng. Code vẫn hoạt động (Flutter chỉ cần biết là cần rebuild), nhưng nó phá vỡ hợp đồng của `setState`: mọi thay đổi state phải nằm *trong* callback. Đây là pattern sẽ gây khó debug khi state phức tạp hơn ở Phase 1.

**Fix:** `setState(() => _log.add(result));` — xem đoạn code ở CR-02.

### IN-02: Ba hàm chạy test trùng lặp logic

**File:** `spike_platform/lib/main.dart:71-95`

**Issue:** `_runAllTests`, `_rerunSqliteTest` và `_rerunFirebaseTest` lặp lại cùng một khuôn "await → add log → debugPrint → setState". Hệ quả thực tế: bản fix `mounted` ở CR-02 phải được áp dụng thủ công ở cả bốn vị trí, rất dễ sót một chỗ.

**Fix:** Rút thành một helper duy nhất:
```dart
Future<void> _run(Future<String> Function() test) async {
  final result = await test();
  debugPrint('[SPIKE] $result');
  if (!mounted) return;
  setState(() => _log.add(result));
}

Future<void> _runAllTests() async {
  await _run(testSqliteInsertAndRead);
  await _run(testFirebaseInitAuthFirestore);
}
```
Nút bấm gọi `_run(testSqliteInsertAndRead)` và `_run(testFirebaseInitAuthFirestore)`.

### IN-03: Tiền tố `k` dùng cho getter runtime; hai getter trùng nội dung

**File:** `spike_platform/lib/platform_config.dart:20-24`

**Issue:** Quy ước `k` trong Dart/Flutter dành cho hằng compile-time (`kDebugMode`, `kToolbarHeight`). `kAuthEmulatorHost` và `kFirestoreEmulatorHost` lại là getter đánh giá lúc runtime, nên tên gây hiểu nhầm. Hai getter cũng có thân hàm y hệt nhau — nếu sau này chỉ sửa một cái, sẽ có bug lệch host rất khó thấy.

**Fix:**
```dart
/// Host để tiếp cận Firebase Emulator Suite từ app đang chạy.
/// Android emulator không thấy `localhost` của máy host — phải dùng alias 10.0.2.2.
String get emulatorHost => Platform.isAndroid ? '10.0.2.2' : 'localhost';
```
Dùng chung `emulatorHost` cho cả Auth lẫn Firestore trong `main.dart`.

### IN-04: Metadata còn nguyên boilerplate của Flutter template

**File:** `spike_platform/pubspec.yaml:2`, `spike_platform/README.md`, `spike_platform/android/app/build.gradle.kts:24`

**Issue:** `description: "A new Flutter project."` và toàn bộ README vẫn là template mặc định — không nói đây là spike throwaway của Phase 0, cũng không cảnh báo rằng code này không được chép sang Phase 1. Comment `// TODO: Specify your own unique Application ID` ở `build.gradle.kts:24` đã lỗi thời vì `applicationId` bên dưới đã được đặt thành `com.memocard.spike.spike_platform`.

Với code throwaway, phần lớn chuyện này không quan trọng — nhưng README chính là nơi phải chứa hướng dẫn tái lập ở CR-04, nên nên sửa cùng lúc.

**Fix:** Đặt `description: "Phase 0 throwaway spike — verify plain sqflite + Firebase Auth/Firestore on Android emulator. KHÔNG chép code này sang Phase 1."`, viết lại README theo CR-04, và xoá dòng TODO đã hoàn thành ở `build.gradle.kts:24`.

---

_Reviewed: 2026-07-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
