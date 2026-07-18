# Walking Skeleton — Memocard

**Phase:** 1
**Generated:** 2026-07-18

## Capability Proven End-to-End

A developer runs `flutter run -d emulator-5554` and gets a real Memocard app: Material 3 "Academic Precision" light/dark theme applied, a 5-tab persistent bottom-navigation shell (Trang chủ / Thư viện / Lớp học / Bài kiểm tra / Cá nhân) built on `go_router` `StatefulShellRoute`, with the `core/` layer beneath it (SQLite 18-table schema, Firestore schema + rules + local Emulator, 7 Riverpod core providers, cache-first/Firestore-first base repository) fully wired and ready for the 5 feature teams (Phases 2–6) to build their vertical slices on without touching `core/` again.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | Flutter 3.41.9 / Dart 3.11.5, Android-only (no Windows desktop) | Mandatory per PRM393; Windows target dropped 2026-07-18 (STATE.md Decisions) — dev machine lacks MSVC C++ toolchain |
| Project root | Repo root (`prm_proejct/`) becomes the Flutter project root — `pubspec.yaml` sits next to `.planning/` and `CLAUDE.md` | Avoids a redundant nested `memocard/` folder; matches how `.planning/phases/**` already resolves paths relative to repo root |
| Package identity | org `com.memocard`, project `memocard` → `applicationId com.memocard.memocard`, `minSdk 24` | Distinct from Phase 0's throwaway `com.memocard.spike.spike_platform`; `minSdk 24` because Flutter's `MinSdkVersionMigration` silently rewrites any value 16–23 back to `flutter.minSdkVersion` (=24) on every build (Phase 0 finding) |
| State management | Riverpod 3.3.2, `Provider`/`StreamProvider`/`FutureProvider` (no `@riverpod` codegen in Phase 1) | Mandatory per PRM393; plain provider syntax keeps Phase 1's 7 core providers simple and dependency-explicit for 5 developers reading them for the first time |
| Local DB | Plain `sqflite ^2.4.2` (NOT `^2.4.3` — requires Dart `^3.12.0`, unavailable), 18 tables + `server_id`/`dirty_at`/`synced_at` on every table | Mandatory per PRM393; pin proven in Phase 0 spike |
| Backend | Firebase Auth + Cloud Firestore, **dev/test always via Firebase Emulator Suite** (`demo-memocard-dev` project, no real GCP project needed) | Mandatory per PRM393; TEAM-ASSIGNMENT.md Golden Rule 5 — Spark tier is 50K reads/day shared by 5 devs, emulator avoids burning it during daily dev |
| Session storage | `shared_preferences` for cached auth session + role (Phase 2) and theme/language (Phase 2 PROF-04) | Mandatory per PRM393; Phase 1 only provisions the `sharedPrefsProvider`, feature usage lands in Phase 2 |
| Routing | `go_router ^17.3.0`, `StatefulShellRoute.indexedStack` with 5 branches + `/auth/login` outside the shell | v17.x API confirmed in 01-RESEARCH.md; `indexedStack` preserves per-tab state across switches |
| Directory layout | `lib/core/` (locked after Phase 1, immutable to features) + `lib/features/<module>/{domain,data,presentation}` (one folder per developer, Phase 2–6) | TEAM-ASSIGNMENT.md Golden Rule 1–2: no cross-feature imports, `core/` is the only shared surface |
| Repository pattern | `BaseSyncRepository<T>` abstract class: cache-first read, Firestore-first write, `dirty_at`/`synced_at` bookkeeping | FND-10; every feature repository (Phase 2–6) extends this instead of hand-rolling sync logic |
| Connectivity signal | `dart:io` `InternetAddress.lookup` polling (no `connectivity_plus` package) | `connectivity_plus` is not in CLAUDE.md's mandatory package list and is absent from 01-RESEARCH.md's Package Legitimacy Audit table; avoiding it sidesteps the package-legitimacy gate entirely for Phase 1 |
| Real Firebase project | Deferred to a human checkpoint (01-04-PLAN.md) — `firebase login` + `flutterfire configure` + `firebase deploy --only firestore:rules,firestore:indexes` are OAuth/browser-only steps Claude cannot perform | Everything else in Phase 1 (schema, rules content, 7 providers, repository pattern, shell) works against the local Emulator Suite and does NOT block on this checkpoint |
| Phase 0 spike | `spike_platform/` deleted in Wave 1 | Findings already captured in `00-SPIKE-FINDINGS.md`/`STATE.md`; keeping a second `pubspec.yaml`/Android project at repo root next to the real one risks tooling confusion (two `applicationId`s, two `google-services.json` slots) |

## Stack Touched in Phase 1

- [x] Project scaffold (Flutter project at repo root, pinned deps validated under Dart 3.11.5, lint rule for `mounted`-after-`await`, `integration_test/` wired)
- [x] Routing — 5 real tab routes + `/auth/login`, `StatefulShellRoute.indexedStack`
- [x] Database — real read AND write: SQLite 18-table `onCreate` (write) + `sqlite_master`/`PRAGMA table_info` verification (read), on Android emulator via `integration_test`
- [x] UI — 5 interactive tab destinations wired to `go_router`, each showing a distinct placeholder page; one page demonstrates the canonical async-`setState`-with-`mounted`-guard pattern
- [x] Deployment — documented local full-stack run command in `ENVIRONMENT.md`: `firebase emulators:start --only firestore,auth --project demo-memocard-dev` + `flutter run -d emulator-5554`

## Out of Scope (Deferred to Later Slices)

- Real Firebase Auth login/registration UI and logic — Phase 2 (AUTH-01..06)
- Any concrete feature repository (`FlashcardSetRepository`, `ClassroomRepository`, etc.) — Phases 2–6, each extends `BaseSyncRepository<T>`
- Theme *persistence* (SharedPreferences-backed light/dark toggle) — Phase 2 PROF-04; Phase 1 only ships the two `ThemeData` variants and applies `ThemeMode.system`
- Real Inter font asset bundling — DESIGN.md typography falls back to platform default (Roboto) in Phase 1; not a course requirement, cosmetic-only
- Real Firebase project deploy (rules/indexes pushed to the actual shared Spark project) — human checkpoint 01-04-PLAN.md, can complete any time before Phase 2 needs real (non-emulator) auth
- Windows desktop target — withdrawn project-wide 2026-07-18 (FND-02)
- Admin screens, quiz generation, classroom join codes, learning session state machine — all Phase 2–6 feature work

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this skeleton without altering its architectural decisions:

- Phase 2 (Person 1): Auth/Profile/Admin — wires real Firebase Auth into the `/auth/login` route already scaffolded here, adds SharedPreferences session persistence and theme/language toggle
- Phase 3 (Person 2): Flashcard Set — first concrete `BaseSyncRepository<T>` implementation, populates the `/library` tab
- Phase 4 (Person 3): Learning Mode — populates the `/home` tab, proves offline-first via the SQLite cache this phase created
- Phase 5 (Person 4): Classroom — populates the `/classroom` tab
- Phase 6 (Person 5): Quiz/Test — populates the `/quiz` tab
- Phase 7: Integration & QA — full E2E journey across all five slices, real Firebase project (from 01-04's checkpoint) used for final security-rules verification
