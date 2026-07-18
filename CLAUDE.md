<!-- GSD:project-start source:PROJECT.md -->
## Project

**Memocard**

Memocard là ứng dụng flashcard di động (Flutter/Android Studio) dành cho giáo viên và học sinh, giúp kiểm tra và rèn luyện trí nhớ ngắn hạn của học sinh. Học sinh học bài qua flashcard rồi được đánh giá trí nhớ qua bài kiểm tra thuật ngữ lấy từ chính bộ thẻ đó. Giáo viên dạy nhiều lớp có thể quản lý lớp học, giao bộ thẻ, tạo bài kiểm tra và theo dõi kết quả học tập của học sinh mình dạy.

Đây là đồ án môn PRM393 (nhóm GR6, 5 thành viên), nên sản phẩm vừa phải chạy đúng nghiệp vụ, vừa phải chứng minh đủ các kỹ thuật bắt buộc của môn học.

**Core Value:** Học sinh học flashcard xong làm bài kiểm tra sinh ra từ chính bộ thẻ đó, và cả học sinh lẫn giáo viên đều nhìn thấy được kết quả trí nhớ — vòng lặp **học → kiểm tra → thấy tiến độ** phải chạy trọn vẹn.

### Constraints

- **Tech stack**: Flutter + Android Studio — yêu cầu bắt buộc của môn PRM393.
- **Tech stack**: Riverpod cho state management — yêu cầu bắt buộc, không dùng Provider/Bloc/GetX.
- **Tech stack**: `sqflite` thuần cho CSDL local — yêu cầu bắt buộc của PRM393. (Trước đây bắt buộc dùng `sqflite_common_ffi` chỉ vì lý do hỗ trợ nền tảng desktop đã bị loại bỏ; bản thân `sqflite` đã là gói "Mandatory per PRM393" nên yêu cầu môn học vẫn được đáp ứng đầy đủ — xem ghi chú lịch sử 2026-07-18 trong mục Technology Stack bên dưới.)
- **Tech stack**: Firebase (Auth + Firestore) — yêu cầu bắt buộc về BaaS và API call.
- **Tech stack**: SharedPreferences — yêu cầu bắt buộc, dùng cho phiên đăng nhập + role và theme/ngôn ngữ.
- **Team**: 5 thành viên, mỗi người phải sở hữu ≥ 4 màn hình để có đủ dấu vết đóng góp khi chấm điểm.
- **Design**: Bám theo 32 màn hình Stitch có sẵn — không tự do redesign, chỉ bổ sung màn Admin theo cùng ngôn ngữ thiết kế.
- **Dependencies**: 5 người dùng chung 1 Firebase project (free tier Spark) — cần thống nhất security rules và tránh đụng schema.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

> **Change note (2026-07-18):** This document previously required Windows desktop support and `sqflite_common_ffi`. The team dropped the Windows desktop target (self-imposed by the team, not a PRM393 instructor requirement — the dev machine lacks the MSVC C++ "Desktop development with C++" toolchain that Flutter's Windows target needs to compile its native CMake runner) and reverted to plain `sqflite`. `sqflite` itself is still listed as "Mandatory per PRM393" in the Database table below, so the course requirement remains satisfied. This was a deliberate decision, not an oversight — see `.planning/STATE.md` Decisions (2026-07-18) for full rationale.

## Recommended Stack
### Core Framework & Language
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Flutter SDK** | 3.24.0+ | UI framework cross-platform | Required by PRM393; stable Flutter 3.x SDK, Android target |
| **Dart SDK** | 3.5+ | Language runtime | Bundled with Flutter; required for all Dart/Flutter packages |
| **Android Studio** | 2024.1+ | IDE / emulator | Required by PRM393; supports Flutter development out-of-box |
### State Management (MANDATORY)
| Package | Version | Constraint | Purpose | Why |
|---------|---------|-----------|---------|-----|
| **flutter_riverpod** | 3.3.2 | `^3.3.2` | Reactive state management | Mandatory per PRM393; modern, testable, supports async/await with `.future`, `.stream` extensions; avoids callback hell vs older Provider pattern |
| **riverpod_annotation** | 4.0.3 | `^4.0.3` | Code generation annotations | Works with riverpod_generator; enables `@riverpod` + `@Riverpod()` syntax for cleaner provider definitions |
| **riverpod_generator** | 4.0.4 | `^4.0.4` | Code generation for Riverpod | Generates boilerplate (AsyncValue handling, dependency tracking); paired with freezed for immutable models |
### Database (MANDATORY)
| Package | Version | Constraint | Purpose | Why | Platform Support |
|---------|---------|-----------|---------|-----|------------------|
| **sqflite** | 2.4.3 | `^2.4.3` | Local SQLite (Android/iOS/macOS) | Mandatory per PRM393; offline-first cache layer | Android ✓ iOS ✓ macOS ✓ |
### Firebase (MANDATORY)
| Package | Version | Constraint | Purpose | Why |
|---------|---------|-----------|---------|-----|
| **firebase_core** | 4.12.1 | `^4.12.1` | Firebase initialization + multi-app management | Latest (3 days old as of 2026-07-18); mandatory BaaS per PRM393 |
| **firebase_auth** | 6.5.6 | `^6.5.6` | Authentication (email/password, OAuth providers) | Latest; provides same API across all platforms thanks to federated plugin system |
| **cloud_firestore** | 6.7.1 | `^6.7.1` | Backend NoSQL database + REST API | Latest (3 days old); Firestore is source-of-truth, SQLite is offline cache |
### Persistent Local Storage (MANDATORY)
| Package | Version | Constraint | Purpose | Why | Platform Support |
|---------|---------|---------|---------|-----|
| **shared_preferences** | 2.5.5 | `^2.5.5` | Key-value store for session + theme + locale | Mandatory per PRM393; stores Firebase auth token (cached), user role (teacher|student|admin), theme preference, language choice; persistent across app restarts | Android ✓ iOS ✓ macOS ✓ Web ✓ Linux ✓ |
### Navigation (Navigator 2.0 Pattern)
| Package | Version | Constraint | Purpose | Why |
|---------|---------|-----------|---------|-----|
| **go_router** | 17.3.0 | `^17.3.0` | URL-based routing | Cleaner than raw Navigator 2.0; declarative route tree; deep linking support; persistent bottom nav via ShellRoute; type-safe parameter passing |
### Data Models & Serialization
| Package | Version | Constraint | Purpose | Why |
|---------|---------|-----------|---------|-----|
| **freezed** | 3.2.5 | `^3.2.5` | Code generation for immutable model classes | Eliminates boilerplate for `User`, `FlashcardSet`, `Flashcard`, etc.; generates `copyWith`, `toString`, `==`, `hashCode`; works with `json_serializable` for JSON → Dart → JSON conversion |
| **freezed_annotation** | 2.4.4 | `^2.4.4` | Annotation library for freezed | Dependency of freezed; provides `@freezed`, `@immutable` decorators |
| **json_serializable** | 6.14.0 | `^6.14.0` | JSON serialization code generation | Converts Firestore JSON to/from Dart models; works alongside freezed; generates `toJson()` / `fromJson()` methods |
| **json_annotation** | 4.9.0 | `^4.9.0` | JSON serialization annotations | Provides `@JsonSerializable`, `@JsonKey`, `@JsonEnum` for customizing serialization behavior |
### Local Notifications (replacing FCM)
| Package | Version | Constraint | Purpose | Why | Platform Support |
|---------|---------|-----------|---------|-----|
| **flutter_local_notifications** | 22.0.1 | `^22.0.1` | Local notifications (Android + Windows) | **Replaces FCM** (Firebase Cloud Messaging); FCM has no Windows desktop support (explicitly dropped per PRM393 decision); used for learning session reminders, quiz availability, grade notifications; works offline | Android ✓ Windows ✓ iOS ✓ macOS ✓ Web ✓ Linux ✓ |
### Build & Code Generation
| Package | Version | Constraint | Dev-Only | Purpose | Why |
|---------|---------|-----------|----------|---------|-----|
| **build_runner** | 2.15.2 | `^2.15.2` | Yes | Code generation orchestrator | Runs freezed, json_serializable, riverpod_generator; command: `dart run build_runner build` |
| **custom_lint** | 1.2.0+ | `^1.2.0` | Yes | Optional linting rules | Recommended for catching riverpod provider misuse patterns early |
## Installation Instructions
### Step 1: Create Flutter Project
### Step 2: Update `pubspec.yaml`
### Step 3: Get Dependencies
### Step 4: Generate Code
# One-time full generation
# Or watch mode during development
### Step 5: Setup Firebase (via FlutterFire CLI)
# Install FlutterFire CLI
# Configure Firebase for Android
# This generates:
# - lib/firebase_options.dart (platform-specific config)
# - Updates Android native config
### Step 6: Initialize Database
## Alternatives Considered & Why Not
| Category | Recommended | Alternative | Why Not Selected |
|----------|-------------|-------------|------------------|
| **State Management** | flutter_riverpod | Provider, Bloc, GetX | Provider lacks `@riverpod` code gen; Bloc adds boilerplate for async operations; GetX couples UI/logic (not idiomatic Dart) |
| **State Management** | flutter_riverpod | MobX | Heavy runtime reflection; less Dart ecosystem adoption; harder to debug |
| **Database** | sqflite | realm, isar, hive | Realm/Isar less mature for this scope; Hive less battle-tested |
| **Backend** | Firestore + REST | GraphQL (HasuraDB, etc.) | Would require separate API server (team only has 1 free Firebase project); REST via Firestore SDK is simpler for PRM scope |
| **Backend** | cloud_firestore | Supabase (PostgreSQL) | PostgreSQL requires live backend server; Firestore free tier covers PRM scope without ops cost |
| **Auth** | Firebase Auth | Supabase Auth, custom JWT | Firebase Auth is MANDATORY per PRM393; simpler OAuth integration (Google, Facebook) |
| **Notifications** | flutter_local_notifications | FCM, OneSignal | FCM has no Windows desktop support (dropped per PRM393); OneSignal costs $; local notifications sufficient for offline-first app |
| **Navigation** | go_router | Navigator 2.0 raw, AutoRoute | go_router balances declarative syntax with minimal boilerplate; Navigator 2.0 raw is verbose; AutoRoute requires too much annotation for PRM scope |
| **Models** | freezed + json_serializable | manual PODOs (Plain Old Dart Objects) | Would require 100s of lines of boilerplate (`toJson`, `fromJson`, `==`, `hashCode`, `copyWith`) per model; unmaintainable at 18-table schema scale |
| **Models** | freezed + json_serializable | dataclass, built_value | dataclass less battle-tested; built_value older, less active community |
| **Serialization** | json_serializable | manual encoding (nested maps) | Manual JSON parsing error-prone, unmaintainable, no compile-time safety |
| **UI Framework** | Flutter | React Native, Xamarin | Flutter MANDATORY per PRM393 |
## Platform Support Matrix
### Firebase Packages
| Package | Android | iOS | macOS | Web | Linux | Status |
|---------|---------|-----|-------|-----|-------|--------|
| **firebase_core** | ✓ | ✓ | ✓ | ✓ | ✗ | Stable (4.12.1, Jul 2026) |
| **firebase_auth** | ✓ | ✓ | ✓ | ✓ | ✗ | Stable (6.5.6, Jul 2026) |
| **cloud_firestore** | ✓ | ✓ | ✓ | ✓ | ✗ | Stable (6.7.1, Jul 2026) |
### Database Packages
| Package | Android | iOS | macOS | Web | Linux |
|---------|---------|-----|-------|-----|-------|
| **sqflite** | ✓ Native | ✓ Native | ✓ Native | ✗ | ✗ |
### Other Key Packages
| Package | Android | iOS | macOS | Web | Linux |
|---------|---------|-----|-------|-----|-------|
| **shared_preferences** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **flutter_local_notifications** | ✓ | ✓ | ✓ | ✓ (limited) | ✓ (D-Bus) |
| **go_router** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **riverpod** (pure Dart) | ✓ | ✓ | ✓ | ✓ | ✓ |
## Version Pinning Strategy
- **Exact versions used** in pubspec.yaml (not loose `^` ranges) for first week of Foundation Phase
- **After Foundation Phase validates**, loosen to `^X.Y.Z` to allow patch updates
- **Firebase packages** locked tightest: `^4.12.1` for firebase_core (lock minor), `^6.5.6` for firebase_auth, `^6.7.1` for cloud_firestore
- **Riverpod** pinned to `^3.3.2` (mature v3 branch; v4 in dev)
- **Dev dependencies** (build_runner, freezed, etc.) pinned normally; minor version changes don't break generated code
## Dependency Diagram (Key Interactions)
## Quality Assurance Checklist for Team
- [ ] `flutter pub get` succeeds on all 5 machines
- [ ] `dart run build_runner build` generates no errors
- [ ] `flutter run -d android` launches on Android emulator
- [ ] Firebase project linked via `flutterfire configure` (shared credentials in `.env` or iOS provisioning)
- [ ] SQLite init verified: create test DB and query on Android
- [ ] Riverpod provider tree builds without cycles (compile-time check via riverpod_generator)
- [ ] Models serialize/deserialize JSON correctly (write unit test with freezed + json_serializable)
- [ ] Shared Preferences persistence verified (set value, restart app, read back)
- [ ] go_router deep links tested (launch app via URL scheme on Android)
## Troubleshooting by Platform
### Android-Specific Issues
- **Cause:** Accessing wrong directory (emulator vs device vs app-specific storage)
- **Fix:** Use `getDatabasesPath()` from sqflite (handles platform-specific paths automatically)
- **Cause:** Google Play Services not installed in emulator
- **Fix:** Use system image with Google APIs (not plain AOSP); or test on real device
### Cross-Platform Issues
- **Cause:** `build_runner` didn't run or freezed/json_serializable not in dev_dependencies
- **Fix:** `dart run build_runner clean && dart run build_runner build`
- **Cause:** Provider A depends on B, B depends on A (common mistake with family modifiers)
- **Fix:** Restructure to remove cycle; use `.select()` to depend on subset of another provider's state
## Sources
- [Firebase SDK for Flutter Release Notes (Jul 2026)](https://firebase.google.com/support/release-notes/flutter)
- [firebase_core pub.dev (v4.12.1)](https://pub.dev/packages/firebase_core)
- [firebase_auth pub.dev (v6.5.6)](https://pub.dev/packages/firebase_auth)
- [cloud_firestore pub.dev (v6.7.1)](https://pub.dev/packages/cloud_firestore)
- [flutter_riverpod pub.dev (v3.3.2)](https://pub.dev/packages/flutter_riverpod)
- [riverpod_annotation pub.dev (v4.0.3)](https://pub.dev/packages/riverpod_annotation)
- [shared_preferences pub.dev (v2.5.5)](https://pub.dev/packages/shared_preferences)
- [go_router pub.dev (v17.3.0)](https://pub.dev/packages/go_router)
- [freezed pub.dev (v3.2.5)](https://pub.dev/packages/freezed)
- [json_serializable pub.dev (v6.14.0)](https://pub.dev/packages/json_serializable)
- [flutter_local_notifications pub.dev (v22.0.1)](https://pub.dev/packages/flutter_local_notifications)
- [build_runner pub.dev (v2.15.2)](https://pub.dev/packages/build_runner)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
