---
phase: 00-platform-spike
plan: 02
subsystem: infra
tags: [flutter, sqflite, firebase, firebase-auth, cloud-firestore, firebase-emulator]

# Dependency graph
requires:
  - phase: 00-platform-spike (plan 01)
    provides: "spike_platform/ scaffolded project, pinned dependencies, platform_config.dart, firebase_options_spike.dart, Firebase Emulator Suite config"
provides:
  - "testSqliteInsertAndRead() — plain sqflite round-trip proof on Android (no FFI)"
  - "testFirebaseInitAuthFirestore() — Auth signup/signin fallback + Firestore write/read against local emulator"
  - "main.dart wiring both tests to auto-run on app launch, logging '[SPIKE] ' prefixed results to console and rendering them in the UI with 2 re-run buttons"
affects: [00-03-validation-report]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Service functions wrap all logic in try/catch and return a PASS/FAIL-prefixed string instead of throwing, so failures surface in UI/console rather than crashing the app"
    - "Adjacent string-literal concatenation ('LITERAL: ' '$value') used instead of the '+' operator to satisfy both literal-match grep checks and the prefer_interpolation_to_compose_strings lint simultaneously"

key-files:
  created:
    - spike_platform/lib/sqlite_service.dart
    - spike_platform/lib/firebase_service.dart
  modified:
    - spike_platform/lib/main.dart
    - spike_platform/test/widget_test.dart

key-decisions:
  - "Fixed test/widget_test.dart's stale reference to the removed MyApp/MyHomePage counter-demo classes (Rule 3 - blocking) because it broke `flutter analyze` for the whole project; replaced with a smoke test against the new SpikeApp"
  - "Used adjacent string-literal concatenation ('SQLITE PASS: ' '${rows.first}') rather than '+' string concatenation, because '+' triggers the flutter_lints prefer_interpolation_to_compose_strings info-level issue which makes `flutter analyze` exit non-zero"

patterns-established:
  - "PASS/FAIL result strings from spike service functions always begin with an exact, grep-able literal prefix ('SQLITE PASS: ', 'SQLITE FAIL: ', 'FIREBASE PASS: ', 'FIREBASE FAIL: ') for automated verification in Plan 00-03"

requirements-completed: [FND-01, FND-03, FND-04]

# Metrics
duration: ~10min
completed: 2026-07-18
---

# Phase 00 Plan 02: Firebase + SQLite Android Spike Logic Summary

**`sqlite_service.dart` proves plain `sqflite` round-trips on Android (no FFI), `firebase_service.dart` proves Auth Emulator signup/signin + Firestore write/read round-trips, and `main.dart` auto-runs both on launch, logging `[SPIKE] SQLITE/FIREBASE PASS/FAIL: ...` to console and rendering results with 2 re-run buttons in the UI.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-07-18T15:20:49Z (approx, per STATE.md session start)
- **Completed:** 2026-07-18T15:25:54Z
- **Tasks:** 3/3
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments
- `sqlite_service.dart` opens `spike.db` via `getDatabasesPath()`, creates `spike_test` table, inserts and reads back a row, returns `'SQLITE PASS: ...'` / `'SQLITE FAIL: ...'` — zero references to `sqflite_common_ffi` or `databaseFactoryFfi`
- `firebase_service.dart` signs up a hardcoded emulator-only test user, falls back to sign-in on `email-already-in-use` (so the re-run button works on 2nd+ click), writes/reads a Firestore doc, returns `'FIREBASE PASS: ...'` / `'FIREBASE FAIL: ...'`
- `main.dart` initializes Firebase in the required order (`WidgetsFlutterBinding.ensureInitialized()` → `Firebase.initializeApp(options: spikeFirebaseOptions)` → `useAuthEmulator`/`useFirestoreEmulator` → `runApp`), auto-runs both tests on `initState`, logs every result with the exact `[SPIKE] ` prefix, and exposes 2 independent re-run buttons
- `flutter analyze` on the whole `spike_platform` project returns 0 issues after fixing a stale default test file left over from `flutter create`

## Task Commits

Each task was committed atomically:

1. **Task 1: Viết sqlite_service.dart (round-trip sqflite thuần trên Android)** - `33433ed` (feat)
2. **Task 2: Viết firebase_service.dart (Auth signup/signin + Firestore round-trip trên Emulator)** - `1d23d1b` (feat)
3. **Task 3: Viết main.dart — khởi tạo Firebase, trỏ emulator, wire UI tự chạy cả hai test** - `00fbae0` (feat)

**Plan metadata:** (next commit, see end of session)

## Files Created/Modified
- `spike_platform/lib/sqlite_service.dart` - `testSqliteInsertAndRead()`, plain sqflite round-trip, try/catch → PASS/FAIL string
- `spike_platform/lib/firebase_service.dart` - `testFirebaseInitAuthFirestore()`, Auth signup/signin-fallback + Firestore write/read, try/catch → PASS/FAIL string
- `spike_platform/lib/main.dart` - Firebase init + emulator targeting in `main()`, `SpikeApp`/`SpikeHomePage` auto-running both tests on launch, 2 re-run buttons, log list UI
- `spike_platform/test/widget_test.dart` - Rewritten smoke test targeting `SpikeApp` (was referencing removed `MyApp`)

## Decisions Made
- **Adjacent string-literal concatenation instead of `+`:** `flutter_lints`' `prefer_interpolation_to_compose_strings` flags `'X: ' + value.toString()` as an info-level issue, which makes `flutter analyze` exit non-zero. The plan's acceptance criteria require an exact grep match on the closed literal `'SQLITE PASS: '` / `'FIREBASE PASS: '` etc., which plain string interpolation (`'SQLITE PASS: $x'`) cannot satisfy either (no closing quote right after the literal). Adjacent string-literal concatenation (`'SQLITE PASS: ' '${rows.first}'`) is valid, lint-clean Dart and satisfies the literal grep check simultaneously.
- **Fixed stale `test/widget_test.dart`:** Left over from `flutter create`'s counter-demo scaffold (created in Plan 00-01), it referenced `MyApp`, which Task 3 replaced with `SpikeApp`. This broke `flutter analyze` for the whole project (acceptance criteria for Task 3 requires whole-project `flutter analyze` exit 0), so it was in scope for a Rule 3 auto-fix directly caused by Task 3's change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `test/widget_test.dart` referenced removed `MyApp` class, breaking whole-project `flutter analyze`**
- **Found during:** Task 3 (verifying `cd spike_platform && flutter analyze` acceptance criteria)
- **Issue:** `flutter analyze` reported `error - The name 'MyApp' isn't a class - test\widget_test.dart:16:35 - creation_with_non_type` because Task 3 replaced the counter-demo `MyApp`/`MyHomePage` with `SpikeApp`/`SpikeHomePage`, but the default test file (untouched since Plan 00-01's `flutter create`) still imported and instantiated `MyApp`
- **Fix:** Rewrote `test/widget_test.dart` as a smoke test that pumps `SpikeApp` and asserts the `Platform Spike` app bar title and both re-run button labels render
- **Files modified:** `spike_platform/test/widget_test.dart`
- **Verification:** `cd spike_platform && flutter analyze` returns "No issues found!" (exit 0)
- **Committed in:** `00fbae0` (Task 3 commit)

**2. [Rule 1 - Bug] `+`-based string concatenation triggered a lint issue that made `flutter analyze` non-zero**
- **Found during:** Task 1 (first draft of `sqlite_service.dart` used `'SQLITE PASS: ' + rows.first.toString()`)
- **Issue:** `flutter_lints`' `prefer_interpolation_to_compose_strings` rule flags `+`-based string concatenation as an info-level issue; `flutter analyze` treats any reported issue (including info) as a non-zero exit, failing the task's `flutter analyze lib/sqlite_service.dart` acceptance criterion
- **Fix:** Switched to Dart's adjacent string-literal concatenation syntax (`'SQLITE PASS: ' '${rows.first}'`), which is lint-clean and still satisfies the literal-match grep acceptance criteria (`grep -c "'SQLITE PASS: '"` etc.)
- **Files modified:** `spike_platform/lib/sqlite_service.dart` (pattern reused identically in `firebase_service.dart` from the start)
- **Verification:** `flutter analyze lib/sqlite_service.dart` returns "No issues found!"; `grep -c "'SQLITE PASS: '" lib/sqlite_service.dart` = 1
- **Committed in:** `33433ed` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (1 Rule 1 - bug, 1 Rule 3 - blocking)
**Impact on plan:** Both fixes were necessary purely to satisfy the plan's own stated acceptance criteria (`flutter analyze` must exit 0, literal PASS/FAIL strings must be grep-able). No scope creep, no feature additions beyond what the plan specified.

## Issues Encountered
None beyond the deviations listed above.

## User Setup Required
None - no external service configuration required. Verification (running on the live Android emulator against a running Firebase Emulator Suite) is Plan 00-03's job, not this plan's.

## Next Phase Readiness
- All 3 files required by Plan 00-02's `must_haves.artifacts` exist and export the exact function names Plan 00-03 expects (`testSqliteInsertAndRead`, `testFirebaseInitAuthFirestore`)
- `spike_platform/` builds clean: `flutter analyze` on the whole project returns 0 issues
- Regression grep confirms `sqflite_common_ffi`/`databaseFactoryFfi` are absent from every file in `spike_platform/lib/*.dart`
- Not yet verified: actual runtime behavior on the live Android emulator (emulator-5554) against a running `firebase emulators:start` — this is exactly what Plan 00-03 does next. No blockers identified for that step.

## Self-Check: PASSED

- FOUND: `spike_platform/lib/sqlite_service.dart`
- FOUND: `spike_platform/lib/firebase_service.dart`
- FOUND: `spike_platform/lib/main.dart` (modified)
- FOUND: `spike_platform/test/widget_test.dart` (modified)
- FOUND: commit `33433ed` in `git log`
- FOUND: commit `1d23d1b` in `git log`
- FOUND: commit `00fbae0` in `git log`

---
*Phase: 00-platform-spike*
*Completed: 2026-07-18*
