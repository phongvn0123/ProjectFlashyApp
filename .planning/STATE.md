---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Hoàn tất Plan 00-02 (Firebase + SQLite spike logic), sẵn sàng Plan 00-03
last_updated: "2026-07-18T15:28:54.218Z"
last_activity: 2026-07-18
progress:
  total_phases: 8
  completed_phases: 0
  total_plans: 3
  completed_plans: 2
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-18)

**Core value:** Học sinh học flashcard xong làm bài kiểm tra sinh ra từ chính bộ thẻ đó, và cả học sinh lẫn giáo viên đều nhìn thấy được kết quả trí nhớ — vòng lặp học → kiểm tra → thấy tiến độ phải chạy trọn vẹn.
**Current focus:** Phase 00 — platform-spike

## Current Position

Phase: 00 (platform-spike) — EXECUTING
Plan: 3 of 3
Status: Ready to execute
Last activity: 2026-07-18

Progress: [███████░░░] 67%

## Performance Metrics

**Velocity:**

- Total plans completed: 0
- Average duration: - min
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**

- Last 5 plans: -
- Trend: -

*Updated after each plan completion*
| Phase 00-platform-spike P01 | 30 | 3 tasks | 11 files |
| Phase 00-platform-spike P02 | 10min | 3 tasks | 4 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Roadmap: Firebase Windows-support claim (firebase_core 4.12.1 / firebase_auth 6.5.6 / cloud_firestore 6.7.1) is treated as unproven until Phase 0's spike passes — this is the single highest-risk assumption in the project. **[SUPERSEDED 2026-07-18]** Windows desktop target dropped — Firebase now only needs to work on Android emulator; see new decisions below.
- Roadmap: Phase 1 (shared foundation) is a hard serial gate — no feature module (Phases 2-6) starts until `core/` ships and the cross-feature-import grep check returns clean.
- Roadmap: Phases 4, 5, 6 (Learning Mode, Classroom, Quiz) depend on Phase 1 only, not on Phases 2-3 completing — they code against Auth/Set repository interfaces per the stagger strategy and run concurrently with Phases 2-3.
- 2026-07-18: Dropped the Windows desktop target — Memocard now ships Android-emulator-only. Rationale: the Windows-desktop requirement was self-imposed by the team, not a PRM393 instructor requirement; the dev machine lacks the MSVC C++ "Desktop development with C++" toolchain that Flutter's Windows target needs to compile its native CMake runner; research/SUMMARY.md already listed "renegotiate the Windows requirement" as a sanctioned fallback.
- 2026-07-18: Switched `sqflite_common_ffi` → plain `sqflite` for local CSDL. Rationale: `sqflite_common_ffi` was only mandatory as the Windows-compatibility enabler; CLAUDE.md's Technology Stack table already lists `sqflite` itself as "Mandatory per PRM393", so dropping the FFI package while keeping `sqflite` still satisfies the course's local-database requirement.
- [Phase 00-01]: sqflite pin xuống ^2.4.2 (thay vì ^2.4.3 trong CLAUDE.md) vì sqflite 2.4.3 yêu cầu Dart SDK ^3.12.0, toolchain hiện tại (Flutter 3.41.9) chỉ bundle Dart 3.11.5
- [Phase 00-01]: minSdk = 24 (không phải 23) trong build.gradle.kts vì Flutter tool tự động revert mọi minSdk 16-23 về flutter.minSdkVersion (=24) ở mỗi lần build
- [Phase 00-platform-spike]: [Phase 00-02]: Dùng adjacent string-literal concatenation ('X: ' '$value') thay vì '+' để vừa lint-clean vừa thoả literal grep check trong acceptance criteria
- [Phase 00-platform-spike]: [Phase 00-02]: Sửa test/widget_test.dart (Rule 3) vì file mặc định từ flutter create tham chiếu MyApp đã bị Task 3 xoá, làm hỏng flutter analyze toàn project

### Pending Todos

- FCM vs. `flutter_local_notifications` is technically revisitable now that Windows (its original blocker) is dropped — NOT reopened as part of this task. Notifications (NOTF-01..03) remain deferred to v2 per Deferred Items table.

### Blockers/Concerns

- **[RESOLVED/WITHDRAWN 2026-07-18]** Phase 0: Firebase native Windows support for firebase_core 4.12.1 / firebase_auth 6.5.6 / cloud_firestore 6.7.1 was MEDIUM confidence per research/SUMMARY.md and needed spike verification before Phase 1. This blocker no longer applies — the team dropped the Windows desktop target entirely (self-imposed requirement, not a PRM393 instructor requirement; the dev machine lacks the MSVC C++ "Desktop development with C++" toolchain Flutter's Windows target needs). SUMMARY.md's own fallback list already sanctioned "renegotiate the Windows requirement" as an acceptable outcome. Firebase now only needs to prove itself on Android emulator.
- Phase 2: 6 of the 10 Admin screens have no existing design in the Stitch export and must be designed by Person 1 following `academic_precision/DESIGN.md` before/during implementation.
- Firestore Spark free-tier quota (50K reads/day, 20K writes/day) is shared across 5 developers testing concurrently — SUMMARY.md recommends the Firestore Emulator for daily dev to avoid exhausting it.
- **[RESOLVED 2026-07-18]** Phase 0 plans were STALE (5 plans written for the dual-platform scope: a Windows verification wave that could no longer execute, plus `sqflite_common_ffi` + `databaseFactoryFfi` in Waves 1-2). Phase 0 has now been **re-planned Android-only**: the 5 stale plans were deleted (recoverable at `6c86368`) and replaced with 3 new plans covering FND-01/FND-03/FND-04. The new plans pin plain `sqflite ^2.4.3`, target the Firebase Emulator Suite via `10.0.2.2`, and carry regression `grep` assertions proving `sqflite_common_ffi`/`databaseFactoryFfi` are absent from the built code. Verified by gsd-plan-checker (VERIFICATION PASSED, 12 dimensions).
- Phase 0 execution has two **environment prerequisites** that are not code and cannot be satisfied by the executor: (1) an AVD using a **Google APIs** system image — plain AOSP lacks Google Play Services and Firebase Auth will fail; (2) `firebase-tools` installed globally so `firebase emulators:start` can run. Plan 00-03 checks the AVD tag and returns NO-GO if it is wrong.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260718-sfh | Gỡ ràng buộc Windows desktop khỏi tài liệu dự án và chuyển `sqflite_common_ffi` sang `sqflite` thuần | 2026-07-18 | d6ff6f6 | [260718-sfh-go-rang-buoc-windows-desktop-chuyen-sqfl](./quick/260718-sfh-go-rang-buoc-windows-desktop-chuyen-sqfl/) |

## Deferred Items

Items acknowledged and carried forward from previous milestone close:

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| v2 | Notifications (NOTF-01..03), Media uploads (MED-01..03), Analytics (ANL-01..03), Import/Export (IMP-01..02) | Deferred to v2 | Requirements definition, 2026-07-18 |

## Session Continuity

Last session: 2026-07-18T15:28:54.204Z
Stopped at: Hoàn tất Plan 00-02 (Firebase + SQLite spike logic), sẵn sàng Plan 00-03
Resume file: None
