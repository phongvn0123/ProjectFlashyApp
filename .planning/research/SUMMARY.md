# Research Summary — Memocard

**Project:** Memocard (Flashcard + Classroom + Quiz education app)
**Domain:** Flutter cross-platform (Android + Windows desktop), offline-first
**Team:** 5 developers, university course project PRM393
**Researched:** 2026-07-18
**Overall confidence:** HIGH on stack/features/pitfalls, MEDIUM-HIGH on phase estimates

---

## Executive Summary

Memocard is a feature-first Flutter app where 5 developers each own one vertical slice. The architecture is offline-first: **Firestore is the source of truth, SQLite is a one-way cache**. Riverpod handles all state, GoRouter handles navigation.

**The single most important structural finding:** a shared `core/` foundation must be built and locked BEFORE the 5 developers split. Without it they will diverge on provider naming, database init, auth patterns, and Firestore schema — producing merge conflicts that cost more than the 3–4 days the foundation takes.

**The single most important technical risk:** the claim that Firebase gained native Windows support in July 2026. This claim is load-bearing for the entire project and **must be verified in the first 24 hours** (see VERIFY-BEFORE-BUILD below).

---

## Locked Stack

Copy into `pubspec.yaml`. All versions reported as verified against pub.dev on 2026-07-18.

| Layer | Package | Version | Windows |
|-------|---------|---------|---------|
| Framework | Flutter SDK | 3.24.0+ | ✓ |
| Language | Dart SDK | 3.5+ | ✓ |
| State (MANDATORY) | `flutter_riverpod` | ^3.3.2 | ✓ |
| State codegen | `riverpod_annotation` | ^4.0.3 | ✓ |
| State codegen | `riverpod_generator` | ^4.0.4 | ✓ |
| Local DB (MANDATORY) | `sqflite` | ^2.4.3 | — (Android/iOS) |
| Local DB (MANDATORY) | `sqflite_common_ffi` | ^2.4.2 | ✓ **required for Windows** |
| Firebase (MANDATORY) | `firebase_core` | ^4.12.1 | ✓ native |
| Firebase (MANDATORY) | `firebase_auth` | ^6.5.6 | ✓ native |
| Backend (MANDATORY) | `cloud_firestore` | ^6.7.1 | ✓ native |
| Prefs (MANDATORY) | `shared_preferences` | ^2.5.5 | ✓ |
| Routing | `go_router` | ^17.3.0 | ✓ |
| Models | `freezed` | ^3.2.5 | ✓ |
| Models | `json_serializable` | ^6.14.0 | ✓ |
| Notifications | `flutter_local_notifications` | ^22.0.1 | ✓ (WinRT Toast) |
| Build | `build_runner` | ^2.15.2 | ✓ |

**Explicitly NOT in the stack:**
- `firebase_messaging` (FCM) — zero Windows support. Do not add it; adding it breaks the Windows build.
- `firebase_storage` — image/audio upload deferred; v1 accepts URLs only.
- `firebase_core_desktop` — legacy workaround, superseded by native Windows support.
- Drift ORM — raw sqflite is simpler for the team to learn.
- Supabase / Bloc / GetX / Provider — ruled out by course requirements.

---

## ⚠️ VERIFY-BEFORE-BUILD

These claims are load-bearing. Verify on day 1 of Phase 1, before any feature work starts.

### 1. Firebase native Windows support (CRITICAL)

**Claim:** `firebase_core` 4.12.1, `firebase_auth` 6.5.6, and `cloud_firestore` 6.7.1 gained first-class Windows support in July 2026.

**Verification steps:**
```bash
flutter create --platforms=windows,android memocard_spike
cd memocard_spike
flutter pub add firebase_core firebase_auth cloud_firestore
flutterfire configure --platforms=android,windows
# confirm firebase_options.dart contains a windows entry
flutter run -d windows
```
Then in the spike: sign up a user, write one Firestore document, read it back.

**If it fails, fallbacks in order of preference:**
1. Firebase Auth via REST API (`identitytoolkit.googleapis.com`) + Firestore via REST — works everywhere, more code.
2. Demo the full app on Android only; Windows build runs SQLite-only mode with a stub auth.
3. Renegotiate the Windows requirement with the instructor.

**Additional caveat found in official Firebase docs:** Firebase on Windows is documented as intended for *local development workflows*, not production. Acceptable for a course project — but state this openly in the report rather than claiming production readiness.

### 2. Package versions

Version numbers move fast. Before Phase 1 commits `pubspec.yaml`, run:
```bash
flutter pub outdated
```
A wrong pin blocks all 5 developers simultaneously, so one person owns this file.

---

## Feature Landscape

### Table stakes — demo fails without these
- Register / login / logout (identity)
- Flashcard set CRUD (the content)
- Study session: flip card, mark known/unknown, see result (**the core loop**)
- Teacher creates class + student joins via code
- Quiz created from a flashcard set, auto-graded MCQ
- Results visible to both student and teacher
- Admin user list + lock/unlock + reset password

### Differentiators
- Offline study (enabled by the SQLite cache)
- Progress tracking (known vs unknown over time)
- Class-level analytics for teachers
- Favourite sets, public set browsing
- Assignment progress tracking

### Anti-features — deliberately not built
Spaced repetition (SM-2/Anki), two-way sync, FCM push, Firebase Storage uploads, essay questions, collaborative set editing, CSV import, AI-generated cards.

### Safe cut order — drop from the top if time runs short
1. Profile pictures (use initials)
2. Shuffle quiz question order
3. Quiz time limits
4. Class activity feed (show assigned sets only)
5. Resume interrupted study session
6. Duplicate set
7. Detailed quiz analytics (pass/fail only)

### Never cut
Core CRUD for sets/quizzes/classes · auto-grading logic · result screens for both roles · classroom join-code flow · the study loop itself.

---

## Architecture

### Layering
```
Firestore (source of truth)
      ↕
  Repository  ──  reads: SQLite cache first, fall back to Firestore, then cache
      ↕            writes: Firestore first, sync SQLite on success
   SQLite (one-way cache; sync metadata on every table)
      ↕
Riverpod providers  ──  features read core providers, never write to them
      ↕
   Feature UI
```

### Firestore collection design (from the relational 18-table ERD)
5 root collections + subcollections:
- `users/{uid}` — profile, role, status
- `flashcard_sets/{setId}` — + subcollection `flashcards`
- `classrooms/{classId}` — + subcollections `members`, `assigned_sets`, `activities`
- `quizzes/{quizId}` — + subcollections `questions`, `options`
- `quiz_attempts/{attemptId}` — **root, not nested** under quizzes, so cross-quiz queries work

**Denormalization required:** card front/back copied into session cards (avoids per-card fetch while studying); teacher name copied into classroom doc; set counts copied into parent docs.

**Queries Firestore handles badly:** aggregations (count/sum) — pre-compute on write; "all public sets sorted by date" — needs a dedicated index or a denormalized collection; "assignments not yet started" — query progress docs, absence means not started.

### SQLite cache schema
Mirrors the 18 tables, plus sync metadata on every table: `server_id`, `dirty_at` (null = clean), `synced_at` (null = never synced).

### The core/ boundary — the anti-conflict rule
Features may import **only** from `core/`. Cross-feature communication goes through Riverpod providers, never direct imports.

Enforcement check:
```bash
grep -r "import.*package:memocard/features/" lib/features/   # must return nothing outside tests
```

**7 shared core providers:** `authStateProvider`, `currentUserProvider`, `userRoleProvider`, `databaseProvider`, `connectivityProvider`, `themeProvider`, `routerProvider`.

---

## Pitfalls Ranked by Blast Radius

### CRITICAL — blocks all 5 developers

| # | Pitfall | Detection | Prevention |
|---|---------|-----------|------------|
| 1 | **sqflite FFI not initialized on Windows** — works on Android, crashes on Windows with "Failed to load sqlite3.dll". Hardest bug to catch because Android hides it. | Windows run crashes on first DB touch | `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` in `main()` guarded by `Platform.isWindows \|\| Platform.isLinux`. Test Windows DB open in Phase 1. |
| 2 | **Firebase Windows startup crash** | "Firebase not initialized" on Windows | `flutterfire configure --platforms=android,windows`; never add `firebase_messaging`. |
| 3 | **Firestore Spark quota exhausted** — 50K reads/day; 5 devs testing concurrently can burn it before noon, blocking everyone | Firebase console usage graph | See "Firebase project strategy" below. Per-dev test-data prefixes. Daily quota check. |
| 4 | **Firestore N+1 reads** — list sets → fetch cards per set → fetch progress per card = 100+ reads for one screen | Read count per screen | Denormalize counts into parent docs; batch fetch; document read cost in a comment above each query. |
| 5 | **Firestore schema divergence** — two devs interpret the ERD differently (session as subcollection vs root) | Day 5: query returns empty for one dev | Phase 1 ships `core/constants/firestore_collections.dart` + `FIREBASE_SCHEMA.md` as the single source of truth. |
| 6 | **Features import each other directly** — creates circular deps and breaks on refactor | The grep above returns hits | Providers only. Enforce in code review. |

### HIGH

| # | Pitfall | Prevention |
|---|---------|-----------|
| 7 | Riverpod codegen defaults to `autoDispose` — data silently reloads on navigation | `@Riverpod(keepAlive: true)` for data meant to persist; document the rule |
| 8 | Firestore listener leaks via StreamProvider | Always `.autoDispose` + `ref.onDispose()` cleanup |
| 9 | Stale cache after write | Set `is_synced = false` until Firestore confirms; `ref.invalidate()` after sync; show a pending-changes indicator |
| 10 | Missing composite index — works locally, fails at demo | Commit `firestore.indexes.json`; `firebase deploy --only firestore:indexes` before demo |
| 11 | Security rules written too late — grader reads another student's results = instant fail | Write baseline rules in Phase 1, before any data exists; test in Rules Playground with 3 identities |

### MEDIUM — team process

| # | Pitfall | Prevention |
|---|---------|-----------|
| 12 | `pubspec.yaml` merge conflicts | One nominated dependency owner; `.gitattributes`: `pubspec.lock merge=union` |
| 13 | Generated `.g.dart` / `.freezed.dart` conflicts | Gitignore them; `dart run build_runner build --delete-conflicting-outputs` after every pull; pre-commit hook |
| 14 | Demo crashes on grader's machine | `ENVIRONMENT.md` with exact SDK versions; clean-machine test one week before demo |
| 15 | Individual contribution unreadable in git history | Branch naming `feature/<module>-<name>`; meaningful commit messages; each dev owns their folder |
| 16 | Scope creep — committing to all 60 UCs then skipping testing | Lock MVP in week 1; code freeze at end of week 3 |

---

## Firebase Project Strategy — OPEN DECISION

The Spark free tier gives 50K reads/day, 20K writes/day. Three options, each with a real tradeoff:

| Option | Quota | Index sync | Risk |
|--------|-------|-----------|------|
| **One shared project** | 50K/day split 5 ways | Automatic — everyone shares indexes | Quota exhaustion blocks the whole team at once |
| **One project per dev + one demo project** | 50K/day each | Manual — indexes must be exported/imported, easy to drift | Someone's query works locally, fails on demo project |
| **Shared project + Firestore emulator locally** | Unlimited locally | Automatic | Extra setup; emulator behavior differs slightly from prod |

**Recommendation:** shared project for the demo/integration environment + **Firestore emulator for daily development**. This removes the quota risk entirely and keeps indexes in one place. Emulator setup belongs in Phase 1.

---

## Phase Structure Implications

### Phase 1 — Foundation (3–4 days, serial, blocks everyone)
Owned by 1–2 people. Everyone else writes screen skeletons and finalizes SRS details meanwhile.

Delivers:
- Flutter project + `pubspec.yaml` pinned
- `main.dart` with sqflite FFI init + Firebase init, **verified running on Android AND Windows**
- SQLite schema: 18 tables + sync metadata + migration scaffolding
- `firestore_collections.dart` + `FIREBASE_SCHEMA.md` + baseline security rules + `firestore.indexes.json`
- 7 shared Riverpod core providers
- GoRouter config + app shell + 5-tab bottom nav
- `ThemeData` from `academic_precision/DESIGN.md` (light + dark)
- Base repository interface + dual-source template + shared widgets + error handling
- `CONTRIBUTING.md`, `GIT_WORKFLOW.md`, `DEVELOPER_GUIDE.md`, `ENVIRONMENT.md`

Definition of Done: all 5 devs can clone, `flutter pub get`, and run on both Android and Windows; the enforcement grep returns nothing.

### Phase 2 — Feature modules (parallel, 6–8 days each)
| Owner | Module | Screens | Can start |
|-------|--------|---------|-----------|
| 1 | Auth + Profile + Admin | 10 (4 designed + 6 to design) | after Phase 1 |
| 2 | Flashcard Set | 5 | after Phase 1 |
| 3 | Learning Mode | 10 | after Auth + Flashcard skeleton |
| 4 | Classroom | 7 | after Auth + Flashcard skeleton |
| 5 | Quiz / Test | 7 | after Auth + Flashcard skeleton |

Stagger strategy: modules 3–5 start against repository *interfaces* immediately, with concrete implementations injected via Riverpod later. This avoids hard blocking.

### Phase 3 — Integration & QA (2–3 days)
E2E: register → login → create set → study → create quiz from set → assign to class → student joins → takes quiz → both roles see results. Offline test: disable network mid-session, reconnect, verify sync. Security rules tested with 3 identities.

### Phase 4 — Docs & release (1 day)
README, build instructions for APK + Windows exe, the 5-person contribution matrix, demo rehearsal on a clean machine.

**Critical path:** ~15–16 days.

---

## Confidence Assessment

| Area | Confidence | Note |
|------|-----------|------|
| Stack versions | HIGH | Verified against pub.dev; still re-run `flutter pub outdated` at Phase 1 |
| Firebase Windows support | **MEDIUM** | Claimed verified but load-bearing — treat as unproven until the day-1 spike passes |
| Features / scope | HIGH | SRS supplies 60 UCs; table stakes cross-checked against Quizlet, Anki, Brainscape |
| Architecture | HIGH | Offline-first + repository + feature-first are proven Flutter patterns |
| Pitfalls | HIGH | Sourced from official docs and issue trackers, not generic advice |
| Phase estimates | MEDIUM-HIGH | Inferred from dependencies and team size; validate with the team on day 1 |

## Gaps to Close

1. **Firebase Windows spike** — day 1, before anything else.
2. **Firebase project strategy** — shared vs per-dev vs emulator. Needs a team decision.
3. **Composite index inventory** — enumerate every `where() + orderBy()` query during Phase 1.
4. **Security rules coverage** — all 5 root collections, tested with student/teacher/admin identities.
5. **6 Admin screens** — no designs exist; Person 1 designs them from `academic_precision/DESIGN.md`.
