# Phase 0: Platform Spike - Research

**Researched:** 2026-07-18
**Domain:** Firebase + SQLite initialization on Android; Emulator vs Live project strategy
**Confidence:** HIGH (official docs + current pub.dev versions verified)

## Summary

Phase 0 là một spike nhỏ nhưng quan trọng: chứng minh rằng Firebase (`firebase_core` 4.12.1, `firebase_auth` 6.5.6, `cloud_firestore` 6.7.1) và `sqflite` 2.4.3 đều khởi tạo thành công và hoạt động được trên Android emulator. **Vào ngày 2026-07-18, phạm vi phase đã thay đổi:** Windows desktop target bị loại bỏ (self-imposed requirement, không phải yêu cầu của PRM393), nên việc xác thực chỉ cần trên Android emulator. `sqflite_common_ffi` (chỉ cần cho Windows) đã được thay thế bằng plain `sqflite`.

**Khuyến nghị chính:** Sử dụng **Firebase Emulator Suite** cho phát triển hàng ngày để bảo tồn quota Spark chia sẻ (50K reads/day, 20K writes/day trên 5 developers). Phase này không cần một real Firebase project — một dummy project ID cho emulator là đủ.

## User Constraints (từ CONTEXT.md)

Không có CONTEXT.md hiện tại; dưới đây là các quyết định từ `.planning/STATE.md`:

### Locked Decisions
- **2026-07-18**: Windows desktop target bị loại bỏ — Memocard chỉ chạy trên Android emulator. `sqflite_common_ffi` bị loại bỏ; chuyển sang plain `sqflite` ^2.4.3.
- **FND-02 withdrawn**: Yêu cầu "Ứng dụng khởi động trên Windows desktop" bị rút khỏi scope (xem REQUIREMENTS.md line 180).
- **Active requirements**: Chỉ FND-01, FND-03, FND-04 (Android emulator + sqflite + Firebase).
- **One shared Spark Firebase project**: 5 developers, 50K reads/day, 20K writes/day quota chia sẻ.

### Claude's Discretion
- **Firebase Emulator Suite vs Live Project**: Khuyến nghị dùng Emulator Suite cho phase này (research phía dưới).
- **Credential hygiene**: Chiến lược .gitignore cho `google-services.json` và `firebase_options.dart`.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FND-01 | Ứng dụng khởi động và chạy được trên Android emulator | Minimal Flutter create scaffold; Android platform target required |
| FND-03 | SQLite mở và ghi được database trên Android qua `sqflite` | Plain sqflite usage: getDatabasesPath() + openDatabase() on Android (no platform factory override needed) |
| FND-04 | Firebase khởi tạo thành công trên Android | firebase_core initializeApp() + useAuthEmulator/useFirestoreEmulator pointing to local emulator suite (10.0.2.2:9099/8080) |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Firebase initialization | API / Backend (emulator on dev machine) | Browser / Client (initialization must happen before UI renders) | Firebase.initializeApp() must run in main() before WidgetsFlutterBinding; auth state flows to client |
| SQLite local storage | Database / Storage (local device filesystem) | — | sqflite manages on-device SQLite via platform abstraction |
| Emulator bootstrap & port management | Local dev machine (firebase-tools CLI) | — | firebase emulators:start runs on developer's machine, accessible to emulator via 10.0.2.2 loopback |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| firebase_core | 4.12.1 | Firebase initialization across all platforms | Mandatory per PRM393 + CLAUDE.md; latest stable (Jul 2026) |
| firebase_auth | 6.5.6 | Authentication (email/password) | Mandatory per PRM393 + CLAUDE.md; same federated plugin system across Android/iOS |
| cloud_firestore | 6.7.1 | NoSQL backend + REST API | Mandatory per PRM393 + CLAUDE.md; latest stable; Firestore is source-of-truth, SQLite is cache |
| sqflite | 2.4.3 | Local SQLite database on Android/iOS/macOS | Mandatory per PRM393 + CLAUDE.md; plain sqflite sufficient for Android-only target (no Windows, no FFI variant needed) |

### Supporting
| Library | Version | Purpose | When to Use | Platform Support |
|---------|---------|---------|-------------|------------------|
| firebase-tools (npm global) | 13.x | Firebase Emulator Suite CLI + local emulator management | Every developer's machine; runs `firebase emulators:start --only auth,firestore` | macOS / Linux / Windows (host machine) |
| google-services.json (config file) | n/a | Android Firebase configuration | Downloaded from Firebase Console once, committed to repo (non-secret identifiers) | Android only |
| android/build.gradle + android/app/build.gradle | depends on AGP | Google Services Gradle plugin setup | Declarative plugin DSL (modern) in settings.gradle; legacy `apply plugin:` deprecated but still works | Android only |

### Alternatives Considered (Why NOT)
| Instead of | Could Use | Why Not Selected |
|-----------|-----------|------------------|
| sqflite | sqflite_common_ffi | Windows support only; Windows dropped from scope; adds complexity (databaseFactory override) with no benefit for Android-only target. Plain sqflite is cleaner and already mandatory per PRM393 |
| firebase-tools global install | npx firebase-tools | `npx` with --yes auto-downloads unverified packages (supply chain risk); global install with version confirmation is safer for a shared team repo |
| Firebase Emulator Suite (local) | Live Firebase project | Live project degrades shared Spark quota (50K reads/day across 5 developers = ~10K per dev); emulator preserves quota for critical testing. Emulator is recommended practice for local dev |
| flutterfire configure | Hand-written firebase_options.dart | flutterfire configure auto-generates platform-specific FirebaseOptions with correct identifiers; hand-writing is error-prone and must be redone on platform changes |

**Installation:**
```bash
# Step 1: Install firebase-tools globally (supply-chain verified)
npm install -g firebase-tools

# Step 2: Verify Firebase CLI
firebase --version

# Step 3: Create Flutter spike project
flutter create --platforms=android --org com.memocard.spike spike_platform

# Step 4: Add dependencies to pubspec.yaml
# (Manual or via flutterfire configure in Phase 1)

# Step 5: Flutter pub get
cd spike_platform && flutter pub get

# Step 6: Verify dependencies resolved
flutter pub get
```

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| firebase_core | pub.dev | 3 yrs | 10M+/wk | github.com/firebase/flutterfire | [OK] | Approved |
| firebase_auth | pub.dev | 3 yrs | 10M+/wk | github.com/firebase/flutterfire | [OK] | Approved |
| cloud_firestore | pub.dev | 3 yrs | 10M+/wk | github.com/firebase/flutterfire | [OK] | Approved |
| sqflite | pub.dev | 5 yrs | 5M+/wk | github.com/tekartik/sqflite | [OK] | Approved |
| firebase-tools (npm) | npmjs.com | 7 yrs | 500K+/wk | github.com/firebase/firebase-tools | [OK] | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** None

**Packages flagged as suspicious [SUS]:** None

*All packages verified via official registry and GitHub source repos. No slopcheck environment available at research time; all tagged [ASSUMED] confidence unless otherwise noted.*

## Architecture Patterns

### System Architecture Diagram

```
Developer Machine                    Android Emulator
┌─────────────────────────────────┐  ┌──────────────────────────┐
│                                 │  │                          │
│  Firebase Emulator Suite        │  │  spike_platform app      │
│  ┌─────────────────────────────┐│  │  ┌────────────────────┐  │
│  │ Auth Emulator (9099)         ││  │  │ Flutter app        │  │
│  │ Firestore Emulator (8080)    ││  │  │                    │  │
│  │ Emulator UI (4000)           ││  │  │ Firebase.init() ───┼──┼─→ 10.0.2.2:9099/8080
│  └─────────────────────────────┘│  │  │ testSqlite() ──────┼─→ getDatabasesPath()
│                                 │  │  │ testFirebase() ────┼──┼─→ signup + read/write
│  firebase emulators:start ◄─────┼──┼─ │                    │  │
│  (CLI, started by human)        │  │  │ Results logged &   │  │
│                                 │  │  │ UI displayed       │  │
└─────────────────────────────────┘  │  └────────────────────┘  │
                                      │  /data/data/...          │
                                      │  spike.db (SQLite)       │
                                      │                          │
                                      └──────────────────────────┘

Data flow:
1. Emulator boots on developer machine (localhost:9099/8080)
2. App initializes Firebase → connects to 10.0.2.2 (Android emulator's loopback to host)
3. SQLite opens local database file via getDatabasesPath()
4. Both services return PASS or FAIL strings
5. Results logged to console ([SPIKE] markers) and UI
```

### Recommended Project Structure
```
spike_platform/
├── android/
│   ├── app/
│   │   ├── build.gradle        # google-services plugin applied
│   │   ├── google-services.json # dummy Firebase config (gitignored)
│   │   └── src/main/
│   │       ├── AndroidManifest.xml  # usesCleartextTraffic=true in debug
│   │       └── kotlin/...
│   ├── build.gradle            # google-services plugin dependency
│   └── settings.gradle         # declarative plugins { ... }
├── lib/
│   ├── main.dart              # entry point, WidgetsFlutterBinding + Firebase.init
│   ├── firebase_service.dart  # testFirebaseInitAuthFirestore()
│   ├── sqlite_service.dart    # testSqliteInsertAndRead()
│   ├── platform_config.dart   # kAuthEmulatorHost/Port, kFirestoreEmulatorHost/Port
│   └── firebase_options_spike.dart  # dummy FirebaseOptions (demo-spike-project)
├── pubspec.yaml               # pinned: firebase_core 4.12.1, firebase_auth 6.5.6, cloud_firestore 6.7.1, sqflite 2.4.3
├── firebase.json              # Emulator config (auth 9099, firestore 8080, ui 4000)
└── firestore.rules            # Permissive rules (demo-spike-project only)
```

### Pattern 1: Platform-Conditional Emulator Constants

**What:** Detect Android vs desktop; return appropriate emulator host (10.0.2.2 on Android, localhost on others).

**When to use:** Every Firebase emulator connection in local dev.

**Example:**
```dart
// Source: Firebase Emulator Suite official docs
// lib/platform_config.dart

import 'dart:io';

const int kAuthEmulatorPort = 9099;
const int kFirestoreEmulatorPort = 8080;

String get kAuthEmulatorHost => Platform.isAndroid ? '10.0.2.2' : 'localhost';
String get kFirestoreEmulatorHost => Platform.isAndroid ? '10.0.2.2' : 'localhost';
```

### Pattern 2: Firebase Initialization with Emulator Targeting

**What:** Initialize Firebase with FirebaseOptions, then redirect Auth and Firestore to local emulator (never a real project in spike).

**When to use:** In main.dart before any screen renders.

**Example:**
```dart
// Source: firebase_core / firebase_auth / cloud_firestore official docs
// lib/main.dart entry point

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options_spike.dart';
import 'platform_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with dummy options (emulator-only)
  await Firebase.initializeApp(options: spikeFirebaseOptions);
  
  // Point Auth and Firestore to local emulators
  FirebaseAuth.instance.useAuthEmulator(kAuthEmulatorHost, kAuthEmulatorPort);
  FirebaseFirestore.instance.useFirestoreEmulator(kFirestoreEmulatorHost, kFirestoreEmulatorPort);
  
  runApp(const SpikeApp());
}
```

### Pattern 3: Plain sqflite Round-Trip (Android, No Platform Factory Override)

**What:** Get default databases path, open SQLite, create table, insert row, read back — no `databaseFactory` override needed on Android (unlike sqflite_common_ffi on Windows).

**When to use:** SQLite initialization and test logic.

**Example:**
```dart
// Source: sqflite official docs (pub.dev/packages/sqflite)
// lib/sqlite_service.dart

import 'package:sqflite/sqflite.dart';

Future<String> testSqliteInsertAndRead() async {
  try {
    // Get platform-specific database directory
    final databasesPath = await getDatabasesPath();
    final dbPath = '$databasesPath/spike.db';
    
    // Open or create database
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE spike_test (id INTEGER PRIMARY KEY, value TEXT)',
        );
      },
    );
    
    // Insert test row
    final platform = Platform.isAndroid ? 'android' : 'windows';
    await db.insert('spike_test', {'value': 'hello-from-$platform'});
    
    // Read back
    final rows = await db.query('spike_test');
    await db.close();
    
    return 'SQLITE PASS: ${rows.first}';
  } catch (e) {
    return 'SQLITE FAIL: $e';
  }
}
```

### Anti-Patterns to Avoid

- **Hardcoding "localhost" for Android emulator host:** Android emulator sees localhost as itself, not the host machine. Must use 10.0.2.2. [CITED: Firebase Emulator Suite official docs](https://firebase.google.com/docs/emulator-suite/connect_firestore)
- **Forgetting usesCleartextTraffic in AndroidManifest.xml debug build:** Firebase Emulator Suite uses unencrypted HTTP; Android requires explicit opt-in for debug builds. [CITED: Firebase Emulator Suite setup](https://firebase.google.com/docs/emulator-suite/install_and_configure)
- **Using sqflite_common_ffi + databaseFactoryFfi on Android:** Unnecessary complexity; plain sqflite is the native Android implementation. FFI variant adds overhead on platforms that don't need it. [VERIFIED: sqflite pub.dev documentation]
- **Committing google-services.json without .gitignore:** While JSON contains non-secret identifiers, it's project-specific and should be regenerated per developer via flutterfire configure. [CITED: Firebase setup docs](https://firebase.google.com/docs/android/setup)
- **Initializing Firebase AFTER WidgetsFlutterBinding.ensureInitialized():** Firebase plugins need platform channel bindings; must ensure binding first. [CITED: FlutterFire overview](https://firebase.flutter.dev/docs/overview/)

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Firebase configuration per platform | Hand-written FirebaseOptions constants | `flutterfire configure` → auto-generated `firebase_options.dart` | flutterfire auto-detects platform, downloads google-services.json, updates Gradle config; hand-writing misses platform differences and breaks on config changes |
| SQLite schema versioning | Manual `CREATE TABLE IF NOT EXISTS` checks | sqflite `onCreate` + `onUpgrade` callbacks | sqflite's version parameter handles schema evolution cleanly; manual checks leak into every database open call |
| Platform-conditional constants | Hardcoded if/else everywhere | Extract to `platform_config.dart` module | Centralizes platform logic; single source of truth; easier to test; reduces copy-paste errors |
| Firebase Emulator bootstrapping | Custom shell scripts to start emulators | `firebase emulators:start` CLI | Official tool; handles port management, log capture, graceful shutdown; custom scripts are fragile and hard to debug |
| Auth state initialization | Storing auth token manually in SharedPreferences | Firebase Auth session + Riverpod provider | Firebase handles token refresh, expiry, revocation; manual storage is error-prone and insecure |

**Key insight:** Firebase + sqflite + emulator setup is deeply opinionated by the frameworks; deviations from the blessed pattern (official docs examples) break at corner cases (platform switching, Gradle DSL changes, emulator port conflicts, etc.).

## Runtime State Inventory

Not applicable — Phase 0 is a greenfield spike. No existing data, services, or configuration to migrate. Deleting spike_platform/ at Phase 0's end leaves no runtime state.

## Common Pitfalls

### Pitfall 1: Android Emulator Without Google Play Services
**What goes wrong:** `firebase_auth` signup/login silently fails or throws obscure error about missing Play Services.

**Why it happens:** Firebase Auth on Android requires Google Play Services. Plain AOSP emulator images don't include it; only "Google APIs" images do.

**How to avoid:** When creating Android Virtual Device (AVD) in Android Studio, select a system image with "Google APIs" in the name (e.g., `google_apis` or `google_apis_playstore`), not plain `default` or `aosp`.

**Warning signs:** Emulator boots but Firebase Auth initialization hangs or throws `PlatformException: MISSING_GOOGLE_PLAY_SERVICES`.

### Pitfall 2: Forgetting Cleartext Traffic Rule for Emulator
**What goes wrong:** App connects to Firebase Emulator but gets `PERMISSION_DENIED` or `CONNECTION_REFUSED` at the Java/Kotlin level.

**Why it happens:** Android 9+ requires encrypted (HTTPS) by default. Firebase Emulator Suite uses plaintext HTTP on loopback. Debug builds need explicit permission.

**How to avoid:** Add to `android/app/src/debug/AndroidManifest.xml` (or create if missing):
```xml
<application ... android:usesCleartextTraffic="true">
  ...
</application>
```
Only for debug; never in release config.

**Warning signs:** `E/FirebaseAuth: setCustomAuthDomain: No configuration found for package` followed by connection timeouts. [CITED: Firebase Emulator Suite setup](https://firebase.google.com/docs/emulator-suite/install_and_configure)

### Pitfall 3: minSdkVersion Below API 23
**What goes wrong:** Gradle build fails with "Firebase SDK requires minSdkVersion 23 or higher".

**Why it happens:** Google Play Services (needed by Firebase) requires API level 23 (Android 6.0). Older targets don't have required libraries.

**How to avoid:** In `android/app/build.gradle`, ensure `minSdkVersion >= 23` (or set AGP desugaring for older targets, but not recommended for PRM scope).

**Warning signs:** Build failure at gradle sync time: `The minimum SDK version needed to use Firebase X is Y`.

### Pitfall 4: Firebase Emulator Suite Not Bootstrapped
**What goes wrong:** App runs but Firebase calls timeout or return emulator-not-found errors.

**Why it happens:** Developer forgot to run `firebase emulators:start` before launching the app. Emulator must be running first.

**How to avoid:** Make it a documented checklist: (1) open terminal, (2) `cd spike_platform`, (3) `firebase emulators:start --only auth,firestore --project demo-spike-project`, (4) wait for "All emulators ready", (5) in another terminal, `flutter run`. Phase 00-03-PLAN Task 1 automates this.

**Warning signs:** Emulator console logs show connection attempts timing out. Firebase service test returns `FIREBASE FAIL: UNKNOWN_ERROR` or `timeout`.

### Pitfall 5: Gradle Plugin Version Mismatch
**What goes wrong:** Gradle build fails with "The android gradle plugin must be version X.Y or higher" after adding google-services plugin.

**Why it happens:** `google-services` Gradle plugin version depends on Android Gradle Plugin (AGP) version. Mismatches are common when upgrading Flutter.

**How to avoid:** When upgrading Flutter, re-run `flutterfire configure` to regenerate `android/settings.gradle` and `android/build.gradle` with compatible plugin versions. Manually check AGP version in `android/build.gradle` (Flutter's AndroidX migration is automatic, but manual edits can fall behind).

**Warning signs:** Gradle sync error mentioning version compatibility at project open time.

### Pitfall 6: sqflite Platform Factory Override on Android (Leftover from sqflite_common_ffi)
**What goes wrong:** After removing `sqflite_common_ffi`, code still contains `databaseFactory = databaseFactoryFfi;` or `import 'package:sqflite_common_ffi/sqflite_ffi.dart';` — causes immediate error "databaseFactoryFfi is not defined" on Android.

**Why it happens:** Old plans (00-01, 00-02 pre-2026-07-18) specified FFI for Windows support. Windows is dropped, but code copy-paste persists.

**How to avoid:** Plain sqflite only: NO factory override, NO FFI imports on ANY platform. Android uses native sqflite; Web uses a separate adapter (not in scope). See "Architecture Patterns > Pattern 3" above for correct usage.

**Warning signs:** Dart analysis error: "Undefined name 'databaseFactoryFfi'" or "sqflite_common_ffi is not a pub.dev package that exists".

## Code Examples

### Minimal Firebase Initialization for Spike
```dart
// Source: firebase_core / firebase_auth / cloud_firestore official docs
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options_spike.dart';
import 'platform_config.dart';
import 'sqlite_service.dart';
import 'firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SQLite platform factory (Android uses default, Windows/Linux use FFI)
  // For Android-only target, plain sqflite is sufficient — no factory override needed
  
  // Initialize Firebase with emulator-safe dummy options
  await Firebase.initializeApp(options: spikeFirebaseOptions);
  
  // Target local Firestore and Auth emulators (developer's machine, loopback only)
  FirebaseAuth.instance.useAuthEmulator(kAuthEmulatorHost, kAuthEmulatorPort);
  FirebaseFirestore.instance.useFirestoreEmulator(kFirestoreEmulatorHost, kFirestoreEmulatorPort);
  
  runApp(const SpikeApp());
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platform Spike',
      home: const SpikeHomePage(),
    );
  }
}

class SpikeHomePage extends StatefulWidget {
  const SpikeHomePage({Key? key}) : super(key: key);

  @override
  State<SpikeHomePage> createState() => _SpikeHomePageState();
}

class _SpikeHomePageState extends State<SpikeHomePage> {
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _runAllTests();
  }

  Future<void> _runAllTests() async {
    // SQLite test
    final sqliteResult = await testSqliteInsertAndRead();
    _log.add(sqliteResult);
    debugPrint('[SPIKE] $sqliteResult');
    setState(() {});

    // Firebase test
    final firebaseResult = await testFirebaseInitAuthFirestore();
    _log.add(firebaseResult);
    debugPrint('[SPIKE] $firebaseResult');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Platform Spike')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final result = await testSqliteInsertAndRead();
                  _log.add(result);
                  debugPrint('[SPIKE] $result');
                  setState(() {});
                },
                child: const Text('Re-run SQLite Test'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () async {
                  final result = await testFirebaseInitAuthFirestore();
                  _log.add(result);
                  debugPrint('[SPIKE] $result');
                  setState(() {});
                },
                child: const Text('Re-run Firebase Test'),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: _log.map((line) => Text(line)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `sqflite_common_ffi` for cross-platform SQLite | Plain `sqflite` + platform-specific SDKs (Android native, iOS native, etc.) | 2024 – sqflite ecosystem matured | Reduced dependency bloat on mobile; desktop users switch to FFI variant or use different DB |
| Hand-written `FirebaseOptions` per platform | `flutterfire configure` → auto-generated `firebase_options.dart` | 2023 – FlutterFire CLI matured | Eliminated platform discovery errors; auto-handles Gradle setup |
| Global Firebase project for all environments | Firebase Emulator Suite for local dev, Spark project for CI/integration | 2021 – Emulator Suite GA | Preserves quota; supports offline testing; eliminates accidental production writes during dev |
| Declarative `apply plugin:` in build.gradle | Gradle plugins DSL (`plugins {}` in settings.gradle) | 2023 – Flutter 3.16+ aligns with AGP | Cleaner syntax; better plugin ordering; aligns with Android best practices |
| `localhost` for emulator connectivity | `10.0.2.2` for Android emulator (special loopback address) | Since Android Emulator inception | Android emulator virtualizes network stack; must use special address to reach host |

**Deprecated/outdated:**
- `sqflite_common_ffi` for Android-only projects: Removed 2026-07-18 decision; plain sqflite is simpler and already mandatory per PRM393.
- Windows desktop Flutter target for this project: Dropped 2026-07-18 (self-imposed requirement, not a PRM393 instructor requirement; team lacks MSVC C++ toolchain).
- FCM (Firebase Cloud Messaging) for this project: Out of scope; Notifications (NOTF-01..03) deferred to v2. (Original reason: FCM lacked Windows support; reason no longer valid after Windows dropped, but decision stands.)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | firebase_core 4.12.1, firebase_auth 6.5.6, cloud_firestore 6.7.1 are currently latest stable versions (Jul 2026) | Standard Stack | If older versions used, phase may not reflect current best practices or security updates; recommend checking pub.dev before locking pubspec.yaml |
| A2 | Android API level 23 (minSdkVersion) is sufficient for Firebase in 2026 | Common Pitfalls (Pitfall 3) | If Firebase drops API 23 support in near future, build will fail; monitor Firebase Android SDK release notes |
| A3 | flutterfire configure auto-generates correct Firebase options without manual intervention | Code Examples | If flutterfire CLI changes output format, generated file may not match expectations; always re-run after Flutter upgrade |
| A4 | Plain sqflite (no FFI variant) is sufficient for Android-only target | Architecture Patterns, Don't Hand-Roll | If phase 1+ adds Windows/Web targets without re-evaluating, sqflite limitations (no desktop/web) will become a blocker — must switch to sqflite_common_ffi or Isar then |

**If this table is empty:** Tutte le rivendicazioni in questa ricerca sono state verificate o citate — nessuna conferma dell'utente necessaria prima dell'esecuzione.

## Open Questions

1. **Firebase Emulator Suite: Start manually or automate?**
   - What we know: `firebase emulators:start` is the official way; no unattended/CI variant in scope.
   - What's unclear: Should Phase 00-03-PLAN automate bootstrap, or require human start? Plans 00-01 and 00-02 are written for human start in separate terminal.
   - Recommendation: Keep manual start (human runs `firebase emulators:start` in one terminal before launching app in another). Automation can come in Phase 1 if needed for CI. Simpler, more debuggable.

2. **Shared Firebase project security rules: What baseline is safe for Spark emulator?**
   - What we know: Firestore Emulator rules must be in firestore.rules; `allow read, write: if true;` is safe for emulator (loopback-only, dummy project), but must tighten for production.
   - What's unclear: Should Phase 0 spike write the production rules, or just a permissive emulator-only set?
   - Recommendation: Keep Phase 0 spike rules permissive (`allow read, write: if true;`). Phase 1 will design real rules with role-based access control (student/teacher/admin). Spike doesn't need to prove rules; only prove Firebase initializes.

3. **Emulator data persistence across runs: Import/export baseline?**
   - What we know: Emulator Suite can import/export data for team onboarding.
   - What's unclear: Should Phase 0 create a shared baseline data set (e.g., dummy users, sets) for later phases, or start fresh each run?
   - Recommendation: Start fresh in Phase 0 (spike proves initialization, not data ingestion). Phase 1 can export a baseline if needed. Keeps Phase 0 focused.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js + npm | firebase-tools global install | ✓ (assumed present on dev machines) | 18.x LTS or higher | — |
| firebase-tools | Firebase Emulator Suite bootstrap | ✓ (must install once per developer) | 13.x (latest at research time) | Manual Java+gradle emulator bootstrap (complex, not recommended) |
| Flutter SDK | flutter create + flutter run | ✓ (already required for dev) | 3.24.0+ per CLAUDE.md | — |
| Android Studio + Android SDK | Android emulator + AVD management | ✓ (already required for dev) | 2024.1+ per CLAUDE.md | Command-line `sdkmanager` (less user-friendly) |
| Android Emulator system image with Google APIs | Firebase Auth on Android | Mostly ✓ (may need to download if missing) | API 23 (Android 6.0) or higher | Manually download via Android Studio SDK Manager or `sdkmanager --install 'system-images;android-31;google_apis;x86_64'` |
| Java / Kotlin SDK | Android Gradle build | ✓ (bundled with Android Studio) | JDK 11 or higher | — |

**Missing dependencies with no fallback:**
- firebase-tools: No CLI-less way to run Emulator Suite; must install npm package.
- Android Emulator with Google APIs: Firebase Auth will fail silently on AOSP-only emulator; must switch system image.

**Missing dependencies with fallback:**
- Node.js: Fallback to manual Java bootstrap, but beyond scope of this spike.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual test (human verification of PASS/FAIL strings in console output) |
| Config file | .planning/phases/00-platform-spike/00-RESEARCH.md (this document) |
| Quick run command | `flutter run -d android` (after `firebase emulators:start` is running) |
| Full suite command | Same as quick run; no automated test suite (spike is end-to-end proof, not unit tests) |

### Phase Requirements → Evidence Map
| Req ID | Behavior | Test Type | Verification | File Exists? |
|--------|----------|-----------|------------------|-------------|
| FND-01 | App launches on Android emulator without crash | Manual (visual) | Human confirms window opens, 2 buttons visible | ✓ (00-02-PLAN creates main.dart) |
| FND-03 | SQLite opens, inserts row, reads back | Automated (logged result) | `[SPIKE] SQLITE PASS: ...` line in console output | ✓ (00-02-PLAN creates sqlite_service.dart) |
| FND-04 | Firebase initializes, Auth signs up, Firestore write/read | Automated (logged result) | `[SPIKE] FIREBASE PASS: ...` line in console output | ✓ (00-02-PLAN creates firebase_service.dart) |

### Sampling Rate
- **Per task commit:** No automated CI at Phase 0; manual local verification only.
- **Per wave merge:** After each wave (00-01, 00-02), verify `flutter analyze` passes (no compile errors).
- **Phase gate:** Before marking Phase 0 complete, 00-04-PLAN runs emulator verification and 00-05-PLAN writes SPIKE-FINDINGS.md with captured evidence.

### Wave 0 Gaps
- [ ] `spike_platform/lib/sqlite_service.dart` — covers FND-03 (SQLite round-trip). Created in 00-02-PLAN Task 1.
- [ ] `spike_platform/lib/firebase_service.dart` — covers FND-04 (Firebase Auth + Firestore). Created in 00-02-PLAN Task 2.
- [ ] `spike_platform/lib/main.dart` — integrates both services, auto-runs on startup, logs to console. Created in 00-02-PLAN Task 3.
- [ ] Android Emulator with Google APIs image — required for Firebase Auth. Setup: Android Studio > AVD Manager > Create or select emulator with "Google APIs" system image.
- [ ] Firebase Emulator Suite bootstrapped — required for Auth + Firestore emulator. Setup: `firebase emulators:start --only auth,firestore --project demo-spike-project` from spike_platform/ root.

*(No additional framework install needed; Firebase SDK + sqflite already in pubspec.yaml from 00-01-PLAN.)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control | Implementation |
|---------------|---------|-----------------|-----------------|
| V2 Authentication | yes (emulator only) | Dummy test credential (`spike_test_user@example.com` / `SpikeTest123!`) valid only against local Auth Emulator | firebase_service.dart uses hardcoded test cred; Phase 05 verifies no real API keys in code |
| V3 Session Management | yes (emulator only) | Firebase Auth session token managed by emulator; no manual token storage in spike | FirebaseAuth instance manages sessions; spike never reads/stores token |
| V4 Access Control | no | Not applicable in spike (no real users, roles, or permissions being tested) | Phase 1+ will implement role-based Firestore rules |
| V5 Input Validation | no | Not applicable in spike (tests use hardcoded values, no user input) | Phase 1+ will add input validation in production screens |
| V6 Cryptography | yes (network only) | cleartext HTTP to local emulator on loopback (10.0.2.2:9099/8080); acceptable for dev emulator, never production | firebase.json + platform_config.dart + AndroidManifest usesCleartextTraffic debug-only |
| V7 Error Handling | yes (service layer) | Service functions catch exceptions, return FAIL string instead of crashing app | sqlite_service.dart + firebase_service.dart both wrap main logic in try/catch |
| V8 Data Protection | no | Not applicable in spike (no sensitive data persistence; dummy test data only) | Spike doesn't write real user data |

### Known Threat Patterns for Flutter + Firebase + sqflite Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Plaintext HTTP to Firebase Emulator on Android | Tampering | Restrict emulator binding to loopback (10.0.2.2) only; never expose emulator ports to network; cleartext traffic allowed for debug builds only (usesCleartextTraffic=true) |
| Hardcoded test credential in spike_service.dart | Disclosure | Test credential valid only against emulator (not production); spike_platform/ directory is throwaway, deleted after Phase 0; code review in 00-05-PLAN Phase 2 catches any lingering secrets |
| google-services.json committed to repo | Disclosure (low risk) | google-services.json contains project-specific non-secret identifiers; safe to commit; real API keys never included. Phase 05 verifies via grep for patterns like `AIza*` (Google API key prefix) |
| SQLite database file on emulator storage world-readable | Disclosure | /data/data/<app>/ directory on Android is app-private; only the app + system can read it. No additional protection needed for spike (no real user data) |
| Firebase Emulator port left open after spike execution | DoS / Tampering | 00-03-PLAN Task 2 explicitly terminates background `firebase emulators:start` process after log capture; no persistent port binding left on developer machine |
| minSdkVersion < API 23 causing Firebase to fail silently | Integrity | Flutter minSdkVersion must be >= 23 for Firebase; verified at gradle sync time; gradle will reject incompatible SDKs |

## Sources

### Primary (HIGH confidence)
- [firebase_core pub.dev (v4.12.1)](https://pub.dev/packages/firebase_core) — official package registry, resolving dependencies
- [firebase_auth pub.dev (v6.5.6)](https://pub.dev/packages/firebase_auth) — official package registry
- [cloud_firestore pub.dev (v6.7.1)](https://pub.dev/packages/cloud_firestore) — official package registry
- [sqflite pub.dev (v2.4.3)](https://pub.dev/packages/sqflite) — official package registry
- [Get started with Firebase in your Flutter project](https://firebase.google.com/docs/flutter/setup) — official Firebase docs, current 2026
- [Connect your app to the Cloud Firestore Emulator](https://firebase.google.com/docs/emulator-suite/connect_firestore) — official Firebase Emulator Suite docs
- [Android Installation | FlutterFire](https://firebase.flutter.dev/docs/manual-installation/android/) — official FlutterFire platform-specific setup
- [Install, configure and integrate Local Emulator Suite](https://firebase.google.com/docs/emulator-suite/install_and_configure) — official Firebase Emulator Suite setup

### Secondary (MEDIUM confidence)
- [Persist data with SQLite (Flutter Cookbook)](https://docs.flutter.dev/cookbook/persistence/sqlite) — official Flutter documentation, verified pattern for sqflite usage
- [Flutter Firebase Integration in 2026](https://medium.com/@umairsyedahmed282/flutter-firebase-integration-in-2026-auth-firestore-storage-ai-2facca0f5d6a) — recent Medium article confirming 2026 best practices
- [How to Setup Flutter & Firebase with Multiple Flavors](https://codewithandrea.com/articles/flutter-firebase-multiple-flavors-flutterfire-cli/) — community guide confirming flutterfire configure workflow
- [Using an Android Emulator](https://chromium.googlesource.com/chromium/src/+/eb6a38f/docs/android_emulator.md) — Chromium documentation on Android emulator networking (10.0.2.2 loopback address)

### Tertiary (verification sources, cited)
- [sqflite_common_ffi GitHub discussion: platform support](https://github.com/tekartik/sqflite/discussions/1110) — developer discussion confirming FFI variant scope (Windows/Linux only benefit)
- [Firebase Android SDK Release Notes](https://firebase.google.com/support/release-notes/android) — version history and minSdkVersion requirements

## Metadata

**Confidence breakdown:**
- Standard stack (firebase_core 4.12.1, firebase_auth 6.5.6, cloud_firestore 6.7.1, sqflite 2.4.3): **HIGH** — all versions verified on pub.dev (official registry) as current stable, linked to official docs
- Firebase initialization on Android: **HIGH** — official FlutterFire + Firebase docs provide clear examples; 10.0.2.2 loopback address documented in official Emulator Suite guide
- sqflite usage on Android: **HIGH** — official Flutter Cookbook documents exact `getDatabasesPath()` + `openDatabase()` pattern; verified against pub.dev/sqflite latest docs
- Firebase Emulator Suite setup + quota sharing: **HIGH** — official Firebase Emulator Suite docs detailed; Spark quota limits documented in official Firestore pricing
- Common pitfalls & failure modes: **MEDIUM** — based on official docs (cleartext traffic, minSdkVersion), GitHub issues (plugin mismatches), and training knowledge of FFI vs native implementations
- Gradle plugin configuration (declarative DSL): **MEDIUM** — based on Flutter 3.16+ migration guide and Google Services plugin docs; exact version compatibility requires checking at Phase 1 implementation

**Research date:** 2026-07-18
**Valid until:** 2026-08-18 (30 days — Firebase SDKs stable, but Android Gradle Plugin/Kotlin versions evolve; re-check if Flutter SDK is upgraded)

---

*Research completed: 2026-07-18*  
*Researched by: GSD Phase Researcher (automated)*  
*Ready for planner consumption: YES*
