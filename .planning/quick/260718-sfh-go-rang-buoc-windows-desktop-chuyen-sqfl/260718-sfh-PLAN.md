---
phase: quick
plan: 260718-sfh
type: execute
wave: 1
depends_on: []
files_modified: [CLAUDE.md, .planning/PROJECT.md, .planning/ROADMAP.md, .planning/STATE.md]
autonomous: true
must_haves:
  truths:
    - "A reader of CLAUDE.md sees Android-emulator-only as the compatibility target, with no active Windows desktop requirement"
    - "A reader of CLAUDE.md sees sqflite (not sqflite_common_ffi) as the mandated local-database package, with the FFI-to-plain-sqflite reasoning preserved as an explicit dated note, not silently erased"
    - "A reader of PROJECT.md sees the same Android-only / sqflite scope as CLAUDE.md — its Active checklist, Out-of-Scope FCM rationale, Constraints, and Key Decisions table are all internally consistent with the Windows-drop decision, with the reversed Key Decision row marked (not deleted)"
    - "A reader of ROADMAP.md sees every phase's success criteria referencing Android only, with no dangling 'and Windows' clauses"
    - "A reader of STATE.md sees the old Windows-support blocker marked resolved/withdrawn (not silently deleted) and two new dated decisions recording why Windows was dropped and why sqflite_common_ffi was swapped for sqflite"
    - "A reader of STATE.md and PROJECT.md sees a one-line note that the FCM-vs-local-notifications decision is technically revisitable now, without FCM actually being re-added or the v2 deferral being touched"
  artifacts:
    - path: "CLAUDE.md"
      provides: "Constraints + Technology Stack sections updated to Android-only / sqflite, with a dated historical note preserving why"
    - path: ".planning/PROJECT.md"
      provides: "Active checklist, Out-of-Scope FCM note, Constraints, and Key Decisions table updated to Android-only / sqflite, with the reversed FCM/Windows decision marked not deleted"
    - path: ".planning/ROADMAP.md"
      provides: "Phase 0, Phase 1, Phase 7 success criteria and overview rewritten Android-only"
    - path: ".planning/STATE.md"
      provides: "Windows blocker resolved, two new dated decisions, FCM-revisitable note"
  key_links:
    - from: "CLAUDE.md Constraints (sqflite line)"
      to: "CLAUDE.md Technology Stack historical note"
      via: "explicit pointer text ('xem ghi chú lịch sử 2026-07-18')"
      pattern: "ghi ch.* l.ch s.*2026-07-18"
    - from: "PROJECT.md Constraints (sqflite line) and Active checklist"
      to: "STATE.md Decisions (2026-07-18)"
      via: "explicit pointer text ('xem STATE.md Decisions 2026-07-18')"
      pattern: "STATE\\.md Decisions 2026-07-18"
---

<objective>
Remove the Windows-desktop compatibility requirement and the `sqflite_common_ffi` dependency from Memocard's planning documents, replacing them with an Android-emulator-only target and plain `sqflite` — while explicitly preserving WHY, so no teammate "fixes" this back thinking it's a mistake.

Purpose: The team confirmed the Windows-desktop requirement was self-imposed (not a PRM393 instructor requirement), and the dev machine lacks the MSVC C++ "Desktop development with C++" toolchain Flutter's Windows target needs to compile its native CMake runner. `sqflite_common_ffi` was only ever mandatory as the Windows enabler — `sqflite` itself is independently listed as "Mandatory per PRM393" in CLAUDE.md's Technology Stack table, so dropping the FFI package while keeping `sqflite` still satisfies the course requirement.

This is a **documentation-only** task. Ground truth: there is no Flutter project in this repo yet (no `pubspec.yaml`, no `lib/`). Do not create, look for, or edit any Dart/Flutter source files — none exist.

Output: Updated `CLAUDE.md`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` — internally consistent, Android-only, with history preserved as dated notes/decisions rather than deleted.

**In scope — all four of these files get edited by this plan:** `CLAUDE.md`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`. (Note: `CLAUDE.md`'s Constraints block is synced from `.planning/PROJECT.md` via `<!-- GSD:project-start source:PROJECT.md -->` — the two files describe the same constraints in the same language and should end up saying the equivalent thing, edited independently in this plan.)

**Do NOT touch (explicitly out of scope):**
- `.planning/REQUIREMENTS.md` — the 92 requirements are phrased functionally, not platform-specific. Do not touch.
- `.planning/phases/00-platform-spike/*-PLAN.md` (the 5 existing plan files) — these are stale and will be re-planned separately right after this task. Leave them alone. (You MAY edit ROADMAP.md's own text about Phase 0 — that file is explicitly in scope — just don't open or edit the actual `00-0X-PLAN.md` files in the phase directory.)
- Do NOT re-enable FCM. Do NOT add FCM to any dependency list. Do NOT change the `flutter_local_notifications` recommendation. Do NOT move NOTF-01..03 out of the v2 deferral in STATE.md's Deferred Items table. The only FCM-related edits permitted anywhere in this plan are: (a) the one-line "now revisitable" note in STATE.md (Task 4), and (b) the annotation on PROJECT.md's FCM exclusion bullet and Key Decisions row (Task 3) — both explicitly say "do not reopen," they don't reopen it. Stop there.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/PROJECT.md
@CLAUDE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: CLAUDE.md — rewrite Constraints section (Vietnamese)</name>
  <files>CLAUDE.md</files>
  <action>
Edit only inside the `<!-- GSD:project-start source:PROJECT.md --> ... <!-- GSD:project-end -->` block's "### Constraints" bullet list (do not touch the HTML comment markers themselves). Match the existing Vietnamese prose style of the surrounding bullets.

1. Delete this bullet entirely:
   `- **Compatibility**: Phải build và chạy được trên cả Android emulator lẫn Windows desktop — quyết định loại bỏ FCM.`
   (The FCM-avoidance decision itself stays — it is now deferred to v2 per STATE.md's Deferred Items table; do not mention or re-justify FCM here.)

2. Replace this bullet:
   `- **Tech stack**: \`sqflite_common_ffi\` cho CSDL local — yêu cầu bắt buộc để chạy được trên Windows, không dùng \`sqflite\` thuần.`
   with:
   `- **Tech stack**: \`sqflite\` thuần cho CSDL local — yêu cầu bắt buộc của PRM393. (Trước đây bắt buộc dùng \`sqflite_common_ffi\` chỉ vì lý do hỗ trợ nền tảng desktop đã bị loại bỏ; bản thân \`sqflite\` đã là gói "Mandatory per PRM393" nên yêu cầu môn học vẫn được đáp ứng đầy đủ — xem ghi chú lịch sử 2026-07-18 trong mục Technology Stack bên dưới.)`

   Note: do NOT use the literal word "Windows" in this rewritten line — say "nền tảng desktop" (desktop platform) generically. The explicit Windows-naming and full reasoning live in the Technology Stack historical note added in Task 2; this line just points to it. This keeps the Constraints section itself Windows-mention-free.

Leave every other Constraints bullet (Flutter, Riverpod, Firebase, SharedPreferences, Team, Design, Dependencies) unchanged, in the same order.
  </action>
  <verify>
    <automated>test "$(sed -n '/GSD:project-start/,/GSD:project-end/p' CLAUDE.md | grep -ic 'windows')" -eq 0 && test "$(grep -c 'sqflite. thuần cho CSDL local' CLAUDE.md)" -ge 1 && test "$(sed -n '/GSD:project-start/,/GSD:project-end/p' CLAUDE.md | grep -ic 'Compatibility')" -eq 0 && echo PASS || echo FAIL</automated>
  </verify>
  <done>Constraints section has no "Windows" mention, the Compatibility bullet is gone, and the sqflite_common_ffi bullet is replaced with a sqflite mandate that explains why and points to the historical note.</done>
</task>

<task type="auto">
  <name>Task 2: CLAUDE.md — sweep Technology Stack section (English) and add historical note</name>
  <files>CLAUDE.md</files>
  <action>
Edit only inside the `<!-- GSD:stack-start source:research/STACK.md --> ... <!-- GSD:stack-end -->` block (do not touch the markers). Match the existing English table-heavy style.

**A. Add a historical note.** Immediately under the `## Technology Stack` heading (before `## Recommended Stack`), insert this as a single unwrapped blockquote line (do not hard-wrap it across multiple lines — it must remain one line so it counts as exactly one grep match):

`> **Change note (2026-07-18):** This document previously required Windows desktop support and \`sqflite_common_ffi\`. The team dropped the Windows desktop target (self-imposed by the team, not a PRM393 instructor requirement — the dev machine lacks the MSVC C++ "Desktop development with C++" toolchain that Flutter's Windows target needs to compile its native CMake runner) and reverted to plain \`sqflite\`. \`sqflite\` itself is still listed as "Mandatory per PRM393" in the Database table below, so the course requirement remains satisfied. This was a deliberate decision, not an oversight — see \`.planning/STATE.md\` Decisions (2026-07-18) for full rationale.`

**B. Core Framework table:** In the Flutter SDK row's "Why" cell, remove "supports Windows desktop via flutter_windows plugin" — reword to something like "stable Flutter 3.x SDK, Android target".

**C. Database (MANDATORY) table:**
- Delete the entire `sqflite_common_ffi` row.
- In the `sqflite` row's "Why" cell, remove "works as dependency for sqflite_common_ffi" (it no longer has that dependency relationship).

**D. Firebase (MANDATORY) table:** This table has a "Windows Support" column. Remove that column entirely (header + all 3 data cells for firebase_core/firebase_auth/cloud_firestore), leaving `| Package | Version | Constraint | Purpose | Why |`. Rewrite each "Why" cell to drop Windows-specific claims (e.g. "Windows support added as native implementation...", "Windows support now native...", "CRITICAL: Windows support now stable...") while keeping the core Android/Firebase-mandatory rationale (e.g. "Latest release as of 2026-07-18; mandatory BaaS per PRM393").

**E. Persistent Local Storage table:** In shared_preferences' Platform Support cell, remove just the "Windows ✓" token, keeping the rest (Android/iOS/macOS/Web/Linux checkmarks) unchanged.

**F. Local Notifications table (flutter_local_notifications row) — DO NOT EDIT.** Leave this entire row (all columns, including "(Android + Windows)" in the header cell and the Windows-related "Why" text) completely untouched. This is a deliberate exception: the FCM-vs-local-notifications reasoning is protected — see Task 4's note about not reopening the FCM decision. Do not remove "Windows" from this row.

**G. Installation Instructions:** 
- `# Configure Firebase for all platforms (auto-detects Windows)` → `# Configure Firebase for Android`
- `# - Updates Android/iOS/macOS/Windows native configs` → `# - Updates Android native config`
- `### Step 6: Initialize Database (Windows FFI)` → `### Step 6: Initialize Database`

**H. Alternatives Considered table:**
- Database row: change "Recommended" cell from "sqflite + sqflite_common_ffi" to "sqflite"; reword "Why Not Selected" cell to drop "don't support Windows desktop equally" language (e.g. "Realm/Isar less mature for this scope; Hive less battle-tested").
- Notifications row — DO NOT EDIT (same protection as item F; this row's "FCM has no Windows desktop support (dropped per PRM393)" reasoning stays untouched).

**I. Platform Support Matrix section:**
- `### Firebase Packages (CRITICAL for Windows Requirement)` → `### Firebase Packages`
- Firebase Packages table: remove the "Windows" column (header + 3 data cells), keeping `| Package | Android | iOS | macOS | Web | Linux | Status |`.
- Remove the 3 bullet points below that table that discuss Windows support claims ("✓ Stable: ... Windows support...", "Eliminated legacy approach: firebase_core_desktop...", "Note: Firebase on Windows is recommended...") — these are now covered by the Task 2A historical note, no need to keep duplicate detail.
- `### Database Packages` table: remove the "Windows" column (header + data cells for sqflite/sqflite_common_ffi rows), then delete the `sqflite_common_ffi` row entirely (package no longer used). Result: `| Package | Android | iOS | macOS | Web | Linux |` with only the `sqflite` row.
- `### Other Key Packages` table: remove the "Windows" column (header + all 4 data cells: shared_preferences, flutter_local_notifications, go_router, riverpod). This is a mechanical column-width change applied uniformly to the whole table, not a change to flutter_local_notifications' description/recommendation/rationale — those stay as protected under item F.

**J. Quality Assurance Checklist:**
- Delete the bullet: `- [ ] \`flutter run -d windows\` launches on Windows without Firebase init errors`
- `- [ ] SQLite FFI init verified: create test DB on Windows, query on Android` → `- [ ] SQLite init verified: create test DB and query on Android`
- `- [ ] go_router deep links tested (launch app via URL scheme on Windows/Android)` → `- [ ] go_router deep links tested (launch app via URL scheme on Android)`

**K. Troubleshooting by Platform:** Delete the entire `### Windows-Specific Issues` subsection (its 2 cause/fix bullet pairs about sqflite_common_ffi and MSVC Runtime). Keep `### Android-Specific Issues` and `### Cross-Platform Issues` unchanged.

**L. Sources list:** Remove these 3 now-irrelevant entries: the `sqflite_common_ffi pub.dev` link, the `Announcing stable FlutterFire Auth for Desktop - Invertase` link, and the `Flutter for Desktop — using Firebase on Windows (iteo Medium)` link. Keep all other source links.

Keep all markdown tables well-formed (matching `|` column counts between header, separator, and data rows) after every column removal.
  </action>
  <verify>
    <automated>test "$(grep -ic windows CLAUDE.md)" -eq 3 && test "$(grep -ic ffi CLAUDE.md)" -eq 1 && test "$(grep -c 'Change note (2026-07-18)' CLAUDE.md)" -eq 1 && test "$(grep -c 'sqflite_common_ffi' CLAUDE.md)" -eq 1 && test "$(grep -c 'explicitly dropped per PRM393 decision' CLAUDE.md)" -eq 1 && test "$(grep -c 'OneSignal costs' CLAUDE.md)" -eq 1 && echo PASS || echo FAIL</automated>
  </verify>
  <done>CLAUDE.md contains exactly 3 case-insensitive "windows" matches after this task (the historical note + the 2 protected FCM/local_notifications rows), exactly 1 "ffi" match (the historical note's sqflite_common_ffi mention), no sqflite_common_ffi table row remains, no "Windows-Specific Issues" subsection remains, and all tables remain well-formed.</done>
</task>

<task type="auto">
  <name>Task 3: PROJECT.md — mirror the Android-only / sqflite scope, void the FCM/Windows rationale, mark the reversed Key Decision</name>
  <files>.planning/PROJECT.md</files>
  <action>
`.planning/PROJECT.md` is the source PROJECT.md that CLAUDE.md's Constraints block syncs from (see `<!-- GSD:project-start source:PROJECT.md -->` marker in CLAUDE.md) — it has 5 of its own Windows/FFI references that need the same treatment as CLAUDE.md, in the same Vietnamese style. Make exactly these 5 edits; touch nothing else in the file.

1. **Line ~28**, under `### Active` > `**Nền móng kỹ thuật (bắt buộc của môn học)**`, replace:
   `- [ ] CSDL local bằng \`sqflite_common_ffi\` (chạy được cả Android lẫn Windows)`
   with:
   `- [ ] CSDL local bằng \`sqflite\` thuần (Android) — yêu cầu bắt buộc của môn học, không còn phụ thuộc \`sqflite_common_ffi\` (xem STATE.md Decisions 2026-07-18)`

2. **Line ~47**, under `### Out of Scope`, the FCM bullet's stated rationale ("FCM không hỗ trợ Flutter Windows desktop...") is now void because the Windows target itself was dropped. Do NOT delete or rewrite the original sentence — append an annotation to the same bullet (same line), so the bullet reads:
   `- **Firebase Cloud Messaging (FCM)** — FCM không hỗ trợ Flutter Windows desktop, xung đột với yêu cầu chạy trên Windows. Thay bằng local notification / thông báo in-app đọc từ bảng \`ClassActivity\`. **[Ghi chú 2026-07-18]:** Lý do gốc (xung đột yêu cầu Windows) không còn hiệu lực vì dự án đã bỏ mục tiêu Windows desktop; quyết định về mặt kỹ thuật có thể xem xét lại, nhưng KHÔNG mở lại FCM trong phạm vi này — Notifications (NOTF-01..03) vẫn deferred sang v2 (xem STATE.md Pending Todos).`

3. **Line ~78**, under `## Constraints`, replace:
   `- **Tech stack**: \`sqflite_common_ffi\` cho CSDL local — yêu cầu bắt buộc để chạy được trên Windows, không dùng \`sqflite\` thuần.`
   with:
   `- **Tech stack**: \`sqflite\` thuần cho CSDL local — yêu cầu bắt buộc của PRM393. (Trước đây bắt buộc dùng \`sqflite_common_ffi\` chỉ vì lý do hỗ trợ nền tảng desktop đã bị loại bỏ; bản thân \`sqflite\` đã là gói "Mandatory per PRM393" nên yêu cầu môn học vẫn được đáp ứng đầy đủ — xem STATE.md Decisions 2026-07-18 để biết lý do đầy đủ.)`
   (Same wording pattern as CLAUDE.md's Constraints edit in Task 1 — no literal "Windows" word, points to STATE.md instead of a local Technology Stack section since PROJECT.md has none.)

4. **Line ~81**, under `## Constraints`, delete this bullet entirely:
   `- **Compatibility**: Phải build và chạy được trên cả Android emulator lẫn Windows desktop — quyết định loại bỏ FCM.`

5. **Line ~90**, in the `## Key Decisions` table, the row `| Firebase Auth có, FCM không | FCM không hỗ trợ Flutter Windows desktop; giữ Windows là yêu cầu cứng. Notification làm bằng local notification + \`ClassActivity\` in-app | — Pending |` records a decision that is now reversed. Do NOT delete the row — keep the Decision and Rationale columns exactly as-is (preserve history), and replace only the Outcome cell (`— Pending`) with:
   `**[REVERSED 2026-07-18]** Lý do gốc (giữ Windows là yêu cầu cứng) không còn hiệu lực — dự án đã bỏ mục tiêu Windows desktop (xem Decision "Dropped Windows desktop target" trong STATE.md). FCM vẫn KHÔNG được bật lại trong phạm vi này vì Notifications (NOTF-01..03) đã deferred sang v2.`
   Result: the row keeps its full original Rationale text (still mentioning "Windows" — that's expected, it's the preserved historical reasoning) with a reversed Outcome.

Do not touch `### Validated`, `### Active`'s other bullets, `### Out of Scope`'s other bullets, `## Context`, the rest of `## Constraints`, `## Evolution`, or any other Key Decisions row.
  </action>
  <verify>
    <automated>test "$(grep -ic windows .planning/PROJECT.md)" -eq 2 && test "$(grep -ic ffi .planning/PROJECT.md)" -eq 0 && test "$(grep -c 'REVERSED 2026-07-18' .planning/PROJECT.md)" -eq 1 && test "$(grep -c 'Ghi chú 2026-07-18' .planning/PROJECT.md)" -eq 1 && test "$(grep -c 'sqflite. thuần' .planning/PROJECT.md)" -eq 2 && test "$(grep -c '\- \*\*Compatibility\*\*.*Windows' .planning/PROJECT.md)" -eq 0 && echo PASS || echo FAIL</automated>
  </verify>
  <done>PROJECT.md contains exactly 2 case-insensitive "windows" matches (the preserved FCM Out-of-Scope rationale and the preserved Key Decisions Rationale cell — both original historical text, not new), 0 "ffi" matches, the FCM bullet has the void-rationale annotation, the Constraints Compatibility bullet is gone, the sqflite_common_ffi mandate is replaced, and the Key Decisions row is marked REVERSED (not deleted).</done>
</task>

<task type="auto">
  <name>Task 4: ROADMAP.md + STATE.md — Android-only sweep and decision log</name>
  <files>.planning/ROADMAP.md, .planning/STATE.md</files>
  <action>
**Part A — `.planning/ROADMAP.md`:**

1. Overview paragraph (top of file): replace "proves the two riskiest technical claims — Firebase and `sqflite_common_ffi` both working on Android emulator AND Windows desktop — before any real code is written" with "proves the riskiest technical claim — Firebase working correctly on Android emulator — before any real code is written (SQLite persistence now uses plain `sqflite`, which needs no separate desktop-FFI validation since the project targets Android only)". Leave the rest of the Overview paragraph unchanged.

2. Phase list bullet: `- [ ] **Phase 0: Platform Spike** - Prove Firebase and sqflite_common_ffi both work on Android emulator and Windows desktop before building anything real` → `- [ ] **Phase 0: Platform Spike** - Prove Firebase and sqflite both work on Android emulator before building anything real`

3. Phase 0 **Goal** line: remove "AND Windows desktop" and change "sqflite_common_ffi 2.4.2" to "sqflite", e.g.: "Prove that Firebase (firebase_core 4.12.1, firebase_auth 6.5.6, cloud_firestore 6.7.1) and sqflite both initialize and work on Android emulator, before any production code depends on that assumption"

4. Phase 0 Success Criteria (currently 4 items): delete criterion 2 ("The same spike app launches without crashing on Windows desktop") entirely. Rewrite criterion 3 to remove "on both Android and Windows" (→ "...via `sqflite` on Android") and criterion 4 to remove "on both Android and Windows" (→ "...on Android"). Renumber the remaining 3 criteria as 1, 2, 3.

5. Phase 0's Plans list, Wave 3 entry: `- [ ] 00-03-PLAN.md — Windows desktop verification run (captured evidence + visual check)` — append a stale marker without rewriting its substance (the actual plan file is out of scope for this task and will be replanned): `- [ ] 00-03-PLAN.md — Windows desktop verification run (STALE — Phase 0 pending replan for Android-only scope, see STATE.md Decisions 2026-07-18)`

6. Phase 1 Success Criterion 1: remove "on both Android and Windows" → "...on every table, openable on Android"

7. Phase 7 Success Criterion 5: remove "for both the Android APK and the Windows executable" → "...for the Android APK"

Do not touch any other phase content (Phases 2-6 have no Windows/FFI references per the sweep already done).

**Part B — `.planning/STATE.md`:**

1. In `### Decisions`, append to the end of the existing bullet about "Firebase Windows-support claim... single highest-risk assumption in the project" (keep the original sentence intact — do not delete it) a superseded marker: append " **[SUPERSEDED 2026-07-18]** Windows desktop target dropped — Firebase now only needs to work on Android emulator; see new decisions below."

2. Still in `### Decisions`, add two new bullets after the existing three (dated, with rationale):
   - `- 2026-07-18: Dropped the Windows desktop target — Memocard now ships Android-emulator-only. Rationale: the Windows-desktop requirement was self-imposed by the team, not a PRM393 instructor requirement; the dev machine lacks the MSVC C++ "Desktop development with C++" toolchain that Flutter's Windows target needs to compile its native CMake runner; research/SUMMARY.md already listed "renegotiate the Windows requirement" as a sanctioned fallback.`
   - `- 2026-07-18: Switched \`sqflite_common_ffi\` → plain \`sqflite\` for local CSDL. Rationale: \`sqflite_common_ffi\` was only mandatory as the Windows-compatibility enabler; CLAUDE.md's Technology Stack table already lists \`sqflite\` itself as "Mandatory per PRM393", so dropping the FFI package while keeping \`sqflite\` still satisfies the course's local-database requirement.`

3. In `### Blockers/Concerns`, mark the Phase 0 Firebase-Windows-support blocker resolved rather than deleting it. Prepend `**[RESOLVED/WITHDRAWN 2026-07-18]**` and rewrite the sentence to explain why: `- **[RESOLVED/WITHDRAWN 2026-07-18]** Phase 0: Firebase native Windows support for firebase_core 4.12.1 / firebase_auth 6.5.6 / cloud_firestore 6.7.1 was MEDIUM confidence per research/SUMMARY.md and needed spike verification before Phase 1. This blocker no longer applies — the team dropped the Windows desktop target entirely (self-imposed requirement, not a PRM393 instructor requirement; the dev machine lacks the MSVC C++ "Desktop development with C++" toolchain Flutter's Windows target needs). SUMMARY.md's own fallback list already sanctioned "renegotiate the Windows requirement" as an acceptable outcome. Firebase now only needs to prove itself on Android emulator.`

4. In `### Pending Todos`, replace "None yet." with one bullet (this is the ONLY FCM-related edit permitted here — do not add FCM as a dependency, do not touch the Deferred Items table, do not change flutter_local_notifications anywhere): `- FCM vs. \`flutter_local_notifications\` is technically revisitable now that Windows (its original blocker) is dropped — NOT reopened as part of this task. Notifications (NOTF-01..03) remain deferred to v2 per Deferred Items table.`

Do not touch the `### Deferred Items` table or any other STATE.md section.
  </action>
  <verify>
    <automated>test "$(grep -ic windows .planning/ROADMAP.md)" -eq 0 -o "$(grep -ic windows .planning/ROADMAP.md)" -eq 1 && test "$(grep -ic ffi .planning/ROADMAP.md)" -eq 0 && test "$(awk '/### Phase 0: Platform Spike/,/### Phase 1: Shared Foundation/' .planning/ROADMAP.md | grep -c '^  [0-9]\.')" -eq 3 && test "$(grep -c 'Dropped the Windows desktop target' .planning/STATE.md)" -eq 1 && test "$(grep -c 'Switched.*sqflite_common_ffi.*plain' .planning/STATE.md)" -eq 1 && test "$(grep -c 'RESOLVED/WITHDRAWN 2026-07-18' .planning/STATE.md)" -eq 1 && test "$(grep -c 'revisitable' .planning/STATE.md)" -eq 1 && test "$(grep -c 'NOTF-01' .planning/STATE.md)" -eq 1 && echo PASS || echo FAIL</automated>
  </verify>
  <done>ROADMAP.md has zero "ffi" mentions and at most one "windows" mention (the intentional stale-marker note on 00-03-PLAN.md), all Phase 0/1/7 success criteria are Android-only and Phase 0 has exactly 3 renumbered criteria. STATE.md has the old Windows blocker marked RESOLVED/WITHDRAWN (not deleted), two new dated decisions present, and exactly one FCM-revisitable note added with the v2 deferral (NOTF-01..03) otherwise untouched.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

None. This is a documentation-only change to four markdown planning files (`CLAUDE.md`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`). No code, dependencies, network calls, or user input are introduced or modified.

## STRIDE Threat Register

Not applicable — no executable code, no new trust boundary, no package installs in this plan.
</threat_model>

<verification>
1. `grep -ic windows CLAUDE.md` returns exactly 3 (historical note + 2 protected FCM/local_notifications rows).
2. `grep -ic ffi CLAUDE.md` returns exactly 1 (historical note only).
3. `grep -ic windows .planning/PROJECT.md` returns exactly 2 (preserved FCM Out-of-Scope rationale + preserved Key Decisions Rationale cell); `grep -ic ffi .planning/PROJECT.md` returns 0.
4. `grep -ic windows .planning/ROADMAP.md` returns 0 or 1 (at most the intentional 00-03-PLAN.md stale marker); `grep -ic ffi .planning/ROADMAP.md` returns 0.
5. `.planning/STATE.md` contains both new dated decisions, the resolved-blocker marker, and the single FCM-revisitable note; the Deferred Items table is byte-for-byte unchanged.
6. `.planning/REQUIREMENTS.md` and `.planning/phases/00-platform-spike/*-PLAN.md` are untouched (`git diff --stat` shows no changes to these paths).
7. No `pubspec.yaml`, `lib/`, or any Dart file was created — this remains a documentation-only commit (`git diff --stat` shows only the 4 target files).
</verification>

<success_criteria>
- CLAUDE.md's Constraints and Technology Stack sections describe an Android-emulator-only, plain-`sqflite` project, with the removed Windows/FFI requirement preserved as an explicit, dated, non-deletable historical note.
- PROJECT.md's Active checklist, Out-of-Scope FCM note, Constraints, and Key Decisions table are internally consistent with the same Android-only / sqflite scope, with the reversed FCM/Windows decision marked (not deleted) and dated.
- ROADMAP.md's Phase 0, Phase 1, and Phase 7 success criteria (and the top-level Overview) are internally consistent with Android-only scope — no dangling "and Windows" clauses.
- STATE.md records the Windows-support blocker as resolved (not silently removed) and logs two new dated decisions explaining both changes, plus the one permitted FCM-revisitable note, without altering the v2 notifications deferral.
- `.planning/REQUIREMENTS.md` and the 5 Phase-0 PLAN.md files remain byte-for-byte unchanged.
</success_criteria>

<output>
Create `.planning/quick/260718-sfh-go-rang-buoc-windows-desktop-chuyen-sqfl/260718-sfh-SUMMARY.md` when done
</output>
</content>
