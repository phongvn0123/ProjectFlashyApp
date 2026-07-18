---
phase: quick
plan: 260718-sfh
subsystem: planning-docs
tags: [documentation, scope-change, windows-drop, sqflite]
dependency-graph:
  requires: []
  provides: ["Android-only project scope", "plain sqflite mandate"]
  affects: ["CLAUDE.md", ".planning/PROJECT.md", ".planning/ROADMAP.md", ".planning/STATE.md"]
tech-stack:
  added: []
  removed: ["sqflite_common_ffi (dependency intent — no code existed yet)"]
  patterns: ["dated historical notes instead of silent deletion"]
key-files:
  created: []
  modified:
    - CLAUDE.md
    - .planning/PROJECT.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
    - .planning/REQUIREMENTS.md
decisions:
  - "Dropped the self-imposed Windows desktop target; project now ships Android-emulator-only"
  - "Switched sqflite_common_ffi -> plain sqflite (sqflite alone already satisfies PRM393's mandatory local-DB requirement)"
  - "FCM stays out of scope — the Windows-conflict rationale that originally justified excluding it is now void, but re-enabling FCM was explicitly out of scope for this task; annotated as revisitable, not reopened"
  - "Reversed Key Decisions row in PROJECT.md ('Firebase Auth có, FCM không') marked [REVERSED 2026-07-18] rather than deleted, preserving the original rationale text"
  - "FND-02 (Windows desktop launch requirement) withdrawn in place, not deleted/renumbered — coordinator identified late that REQUIREMENTS.md was wrongly scoped out"
metrics:
  duration: "~30 min (25 min original 4 tasks + ~5 min follow-up correction)"
  completed: 2026-07-18
---

# Phase quick Plan 260718-sfh: Go rang buoc Windows desktop, chuyen sqflite_common_ffi -> sqflite Summary

One-liner: Removed the self-imposed Windows-desktop compatibility target and the `sqflite_common_ffi` dependency from all five planning documents (CLAUDE.md, PROJECT.md, ROADMAP.md, STATE.md, and — added late via coordinator correction — REQUIREMENTS.md), replacing them with an Android-emulator-only scope and plain `sqflite`, while preserving every removed claim as a dated (2026-07-18) historical note/decision so no teammate silently "fixes" this back.

## What Was Built

This was a documentation-only quick task — no Flutter project exists yet in this repo (no `pubspec.yaml`, no `lib/`), so no code was touched. Five planning documents were edited to reflect a scope decision: the team decided the Windows desktop target was self-imposed (not a PRM393 course requirement) and the dev machine lacks the MSVC "Desktop development with C++" toolchain Flutter's Windows target needs. `sqflite_common_ffi` was only ever needed as the Windows enabler; plain `sqflite` is independently "Mandatory per PRM393", so dropping FFI while keeping `sqflite` still satisfies the course requirement.

**Task 1 — CLAUDE.md Constraints (Vietnamese, commit cc6c3e9):**
Removed the "Compatibility: Android emulator + Windows desktop" bullet entirely. Replaced the `sqflite_common_ffi` mandate bullet with a plain-`sqflite` mandate that explains why (desktop-support reason removed) and points to the Technology Stack historical note, without using the literal word "Windows" in the Constraints section itself.

**Task 2 — CLAUDE.md Technology Stack (English, commit d059cf6):**
Added a dated `> **Change note (2026-07-18):**` blockquote directly under the `## Technology Stack` heading explaining the Windows drop and the FFI→sqflite switch, pointing to STATE.md for full rationale. Then swept the rest of the section: removed the `sqflite_common_ffi` table row, dropped the "Windows Support" column from the Firebase table and reworded its Why cells, removed the Windows checkmark from shared_preferences' Platform Support cell, updated Installation Instructions (Firebase config comment, Step 6 heading), reworded the Alternatives Considered Database row, removed the Windows column from all three Platform Support Matrix tables (Firebase Packages, Database Packages, Other Key Packages) and deleted the `sqflite_common_ffi` row from Database Packages, trimmed the QA Checklist (removed the `flutter run -d windows` line, reworded the SQLite/go_router lines to Android-only), deleted the entire `### Windows-Specific Issues` troubleshooting subsection, and removed the 3 now-irrelevant source links (`sqflite_common_ffi`, FlutterFire Desktop Auth, Firebase-on-Windows). Per the plan's explicit protection, the `flutter_local_notifications` table row and the Alternatives "Notifications" row were left completely untouched — both still say "Windows" because that FCM-avoidance history is intentionally preserved.

**Task 3 — PROJECT.md (commit 247ba76):**
Made the 5 mirrored edits: (1) Active checklist CSDL bullet now says `sqflite` thuần (Android), pointing to STATE.md Decisions 2026-07-18; (2) the FCM Out-of-Scope bullet got an appended `[Ghi chú 2026-07-18]` annotation stating the original Windows-conflict rationale is void but FCM stays closed (Notifications deferred to v2); (3) the Constraints `sqflite_common_ffi` bullet replaced with the plain-`sqflite` mandate pointing to STATE.md; (4) the Compatibility bullet deleted; (5) the Key Decisions row "Firebase Auth có, FCM không" kept its original Decision and Rationale text (still mentioning Windows — intentional, preserved history) but its Outcome cell was replaced with `**[REVERSED 2026-07-18]**` explaining the reversal and reaffirming FCM stays closed.

**Task 4 — ROADMAP.md + STATE.md (commit f5b55b7):**
ROADMAP.md: rewrote the Overview paragraph and the Phase 0 phase-list bullet and Goal line to drop "and Windows desktop" / `sqflite_common_ffi`, replacing with Android-only `sqflite` language. Deleted Phase 0 Success Criterion 2 (the Windows-launch check) and reworded criteria 3-4 (renumbered to 2-3) to drop "on both Android and Windows". Marked the Wave 3 plan bullet (`00-03-PLAN.md`) stale with a pointer to STATE.md Decisions, without touching the actual plan file. Removed "on both Android and Windows" from Phase 1 Success Criterion 1 and "for both the Android APK and the Windows executable" from Phase 7 Success Criterion 5.

STATE.md: appended a `**[SUPERSEDED 2026-07-18]**` marker to the existing Firebase-Windows-support decision bullet (kept intact, not deleted). Added two new dated decision bullets recording the Windows-drop and the sqflite_common_ffi→sqflite switch, each with rationale. Replaced "None yet." in Pending Todos with a bullet noting FCM vs. `flutter_local_notifications` is technically revisitable but explicitly NOT reopened, with the v2 deferral (NOTF-01..03) untouched. Prepended `**[RESOLVED/WITHDRAWN 2026-07-18]**` to the Phase 0 Firebase-Windows blocker in Blockers/Concerns and rewrote it to explain the blocker no longer applies. The Deferred Items table was verified byte-for-byte unchanged (confirmed via `git diff`).

**Task 5 — REQUIREMENTS.md correction (commit d6ff6f6, added mid-execution via coordinator follow-up):**

The original plan explicitly marked `.planning/REQUIREMENTS.md` out of scope, on the stated belief that its 92 requirements were phrased functionally and not platform-specific. That premise was wrong for `FND-01..FND-04`, which are explicitly platform-bound and, after Tasks 1-4, directly contradicted the Windows-drop decision now recorded in CLAUDE.md/PROJECT.md/ROADMAP.md/STATE.md. The coordinator caught this mid-execution and re-scoped `.planning/REQUIREMENTS.md` into the task (while keeping `.planning/phases/00-platform-spike/*-PLAN.md` off-limits, unchanged from the original plan). This is a scoping correction by the coordinator, not a deviation I introduced.

Changes made, all inside `.planning/REQUIREMENTS.md`:
- **FND-01** — left unchanged (already Android-only).
- **FND-02** — marked withdrawn in place rather than deleted or renumbered: `~~Ứng dụng khởi động và chạy được trên Windows desktop~~ **[ĐÃ RÚT 2026-07-18]** — mục tiêu Windows desktop đã bị loại bỏ khỏi phạm vi dự án; xem \`.planning/STATE.md\` Decisions 2026-07-18 để biết lý do đầy đủ`. The requirement ID, its position in the list, and every downstream reference (traceability table, ROADMAP Phase 0) are preserved.
- **FND-03** — reworded from "SQLite mở và ghi được database trên cả Android lẫn Windows qua `sqflite_common_ffi`" to "SQLite mở và ghi được database trên Android qua `sqflite`".
- **FND-04** — reworded from "Firebase khởi tạo thành công trên cả Android lẫn Windows" to "Firebase khởi tạo thành công trên Android".
- **Traceability table** — FND-02's Status cell changed from `Pending` to `**[ĐÃ RÚT 2026-07-18]** — xem STATE.md Decisions`, so it no longer reads as outstanding work owed.
- **Coverage/total counts** — searched the file for any stale total (per the coordinator's explicit instruction not to assume there wasn't one) and found three: the `**Coverage:**` block's "v1 requirements: **92** total" line, its "Mapped to phases: 92/92" line, and the closing "Last updated" line. Updated the total line to spell out "91 active + 1 withdrawn (FND-02, ...)"; updated the mapped-to-phases line to clarify it still counts the withdrawn FND-02 (tracked, not deleted, hence still 92/92 mapped); appended a second dated "Last updated (correction)" line rather than overwriting the original, preserving the original edit history.

## Verification: Predicted vs. Actual Grep Counts

Per the constraint to report actual grep numbers and explain mismatches rather than force the file to match a wrong prediction:

| Check | Plan predicted | Actual | Match? | Explanation |
|---|---|---|---|---|
| CLAUDE.md `windows` count | 3 | 3 | Yes | Historical note + 2 protected FCM/local_notifications rows |
| CLAUDE.md `ffi` count | 1 | 3 | **No** | Plan undercounted: (a) Task 1's own mandated Constraints text contains a literal `sqflite_common_ffi` mention (line 16) pointing to the historical note — this is required text from the plan itself, not an oversight; (b) the historical note itself (line 27, 1 matching line); (c) a false-positive substring match on "suffi**ci**ent" in the protected, untouched Notifications Alternatives row (line 99) — unrelated to FFI, pre-existing text. All 3 matches are either plan-mandated or pre-existing/protected; none indicate a file defect. |
| CLAUDE.md "Change note" count | 1 | 1 | Yes | |
| CLAUDE.md `sqflite_common_ffi` literal count | 1 | 2 | **No** | Same root cause as above: Task 1's Constraints bullet (mandated literal text) plus Task 2's historical note both intentionally contain this string as a pointer/explanation. Both were explicitly required by the plan's own action text. |
| CLAUDE.md "explicitly dropped per PRM393 decision" | 1 | 1 | Yes | |
| CLAUDE.md "OneSignal costs" | 1 | 1 | Yes | |
| PROJECT.md `windows` count | 2 | 2 | Yes | Preserved FCM Out-of-Scope rationale + preserved Key Decisions Rationale cell |
| PROJECT.md `ffi` count | 0 | 2 | **No** | Same pattern: Task 3 items 1 and 3 both mandate literal `sqflite_common_ffi` text (pointing to STATE.md) in the Active checklist bullet and the Constraints bullet respectively. Both are plan-required text, not accidental leftovers. |
| PROJECT.md "REVERSED 2026-07-18" | 1 | 1 | Yes | |
| PROJECT.md "Ghi chú 2026-07-18" | 1 | 1 | Yes | |
| PROJECT.md `sqflite. thuần` count | 2 | 2 | Yes | |
| PROJECT.md Compatibility+Windows bullet | 0 | 0 | Yes | |
| ROADMAP.md `windows` count | 0 or 1 | 1 | Yes | Intentional stale marker on 00-03-PLAN.md line |
| ROADMAP.md `ffi` count | 0 | 1 | **No** | The plan's own mandated Overview rewrite text (item 1) explicitly requires the phrase "desktop-FFI validation" — this is literal text the plan specified verbatim. Not an oversight. |
| ROADMAP.md Phase 0 criteria count | 3 | 3 | Yes | |
| STATE.md "Dropped the Windows desktop target" | 1 | 1 | Yes | |
| STATE.md "Switched...sqflite_common_ffi...plain" | 1 | 1 | Yes | |
| STATE.md "RESOLVED/WITHDRAWN 2026-07-18" | 1 | 1 | Yes | |
| STATE.md "revisitable" | 1 | 1 | Yes | |
| STATE.md "NOTF-01" count | 1 | 2 | **No** | The plan's own item 4 mandates a new Pending Todos bullet containing "NOTF-01..03"; this necessarily co-exists with the pre-existing (untouched, protected) Deferred Items table row that also mentions "NOTF-01..03". Both matches are expected given the plan's own text plus the explicit "do not touch Deferred Items" instruction. `git diff` confirms the Deferred Items table itself is unchanged. |

**Assessment:** All 7 mismatches trace to the same root cause across all four files — the plan's verify-step grep predictions did not account for literal strings the plan's own `<action>` blocks explicitly mandated (either new pointer text referencing `sqflite_common_ffi`/FFI by name, or co-occurrence with pre-existing protected content like the Deferred Items table or the Notifications row). No mismatch indicates a defect in scope, wording, or the must-haves — every `<done>` criterion in the plan (windows-mention-free Compatibility bullet, sqflite mandate present, historical note present, Deferred Items untouched, etc.) is satisfied. I did not alter any file to force these grep counts to match, per the instruction to report actual numbers and explain rather than adjust.

### REQUIREMENTS.md (Task 5, coordinator follow-up — no pre-set predictions, actuals reported as observed)

| Check | Actual | Notes |
|---|---|---|
| `grep -ic windows` | 3 | Line 15 (FND-02 withdrawn text, contains "Windows" twice but counts as 1 matching line), line 159 (pre-existing, untouched Out of Scope FCM row — out of this task's scope, left alone), line 280 (new correction note) |
| `grep -ic ffi` | 0 | FND-03's `sqflite_common_ffi` was fully replaced with `sqflite`; no residual FFI mentions anywhere in the file |
| `grep -c 'ĐÃ RÚT 2026-07-18'` | 3 | FND-02 requirement line (15), traceability table row (180), Coverage summary note (273) — all three intentional, consistent withdrawal marker |
| Stale-total search | 3 found, all updated | `**92** total` line, `92/92` mapped line, and the closing "Last updated" line all referenced the pre-correction 92-active count; all three updated to reflect 91 active + 1 withdrawn = 92 total (still 92/92 mapped since FND-02 stays tracked, not removed) |

No mismatches to report for this task — no pre-existing prediction was given for these greps (the coordinator asked me to report actual numbers directly), and all edits landed exactly as instructed with no unexpected residue.

## Deviations from Plan

None beyond the grep-count discrepancies documented above (which are estimate errors in the plan's verify predictions, not deviations in what was built). All 4 original tasks were executed exactly as specified in `<action>` blocks.

One minor note: Task 2 item K described the `### Windows-Specific Issues` subsection as containing "2 cause/fix bullet pairs about sqflite_common_ffi and MSVC Runtime," but the actual subsection (visible in the pre-edit file) contained 3 cause/fix pairs (sqflite_common_ffi, Firebase emulator, MSVC Runtime). The task's primary instruction — "Delete the entire `### Windows-Specific Issues` subsection" — was unambiguous and was followed in full regardless of the pair-count discrepancy in the description.

**Task 5 was added late, mid-execution, via a coordinator correction — not a self-initiated deviation.** The original PLAN.md explicitly listed `.planning/REQUIREMENTS.md` as out of scope ("the 92 requirements are phrased functionally, not platform-specific"). After Tasks 1-4 completed and I reported the finished work, the coordinator identified that this premise was wrong: FND-01 through FND-04 are explicitly platform-bound requirements, and after the Windows-drop was recorded in the other four files, REQUIREMENTS.md was left contradicting them (FND-02 still demanded Windows desktop launch; FND-03 still named `sqflite_common_ffi`; FND-04 still said "cả Android lẫn Windows"). The coordinator re-scoped REQUIREMENTS.md into the task and I executed the fix as Task 5 in its own atomic commit (`d6ff6f6`), following the same anti-silent-deletion discipline used throughout (FND-02 withdrawn in place with a dated marker and STATE.md pointer, not deleted or renumbered). `.planning/phases/00-platform-spike/*-PLAN.md` remained off-limits throughout and was not touched.

## Known Stubs

None — no code was created; this is a documentation-only change.

## Threat Flags

None — no code, dependencies, network calls, or trust boundaries were introduced or modified. Confirmed via the plan's own threat_model section ("Not applicable").

## Self-Check: PASSED

- FOUND: CLAUDE.md (modified, verified via grep counts above)
- FOUND: .planning/PROJECT.md (modified, verified via grep counts above)
- FOUND: .planning/ROADMAP.md (modified, verified via grep counts above)
- FOUND: .planning/STATE.md (modified, verified via grep counts above)
- FOUND: .planning/REQUIREMENTS.md (modified as of Task 5, verified via grep counts above)
- FOUND: commit cc6c3e9 (Task 1)
- FOUND: commit d059cf6 (Task 2)
- FOUND: commit 247ba76 (Task 3)
- FOUND: commit f5b55b7 (Task 4)
- FOUND: commit d6ff6f6 (Task 5 — REQUIREMENTS.md correction)
- CONFIRMED: .planning/phases/00-platform-spike/*-PLAN.md files untouched throughout all 5 tasks (`git diff --stat cc6c3e9~1 HEAD -- .planning/phases/00-platform-spike/` shows no changes)
- CONFIRMED: no pubspec.yaml, lib/, or Dart file created (`git status --short` shows none)
- CONFIRMED: exactly 5 files changed across all 5 commits (`git diff --stat cc6c3e9~1 HEAD`: CLAUDE.md, .planning/PROJECT.md, .planning/ROADMAP.md, .planning/STATE.md, .planning/REQUIREMENTS.md)
