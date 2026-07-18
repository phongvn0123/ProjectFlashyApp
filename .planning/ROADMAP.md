# Roadmap: Memocard

## Overview

Memocard ships in three movements. First, a tiny throwaway spike (Phase 0) proves the riskiest technical claim — Firebase working correctly on Android emulator — before any real code is written (SQLite persistence now uses plain `sqflite`, which needs no separate desktop-FFI validation since the project targets Android only). Second, one shared foundation (Phase 1) is built serially by 1-2 people: the 18-table SQLite cache, the Firestore schema + security rules, 7 core Riverpod providers, GoRouter shell, theme, and base repository pattern that all five developers will build on. Once that foundation locks, five vertical feature modules (Phases 2-6) run in parallel, one per developer, each owning their `lib/features/<module>/` end-to-end (UI + state + data): Auth/Profile/Admin, Flashcard Set, Learning Mode, Classroom, and Quiz/Test. Modules that depend on identity or content (Learning Mode, Classroom, Quiz) code against repository interfaces from day one so they aren't blocked waiting for concrete Auth/Set implementations. Finally, an integration phase (Phase 7) wires the five modules into one working E2E flow, verifies offline behavior and security rules with real role identities, confirms the 5-person contribution trail, and rehearses the demo on a clean machine.

## Phases

**Phase Numbering:**

- Integer phases (0, 1, 2...): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 0: Platform Spike** - Prove Firebase and sqflite both work on Android emulator before building anything real
- [ ] **Phase 1: Shared Foundation** - Build the core/ layer (schema, providers, routing, theme, base repository, team docs) that all 5 developers build on
- [ ] **Phase 2: Auth, Profile & Admin (Person 1)** - Users can register/login/manage their profile; admins can fully manage the user base
- [ ] **Phase 3: Flashcard Set (Person 2)** - Users can create, browse, edit, duplicate, and favorite flashcard sets
- [ ] **Phase 4: Learning Mode (Person 3)** - Students can study a set end-to-end, online or offline, and see their memory progress
- [ ] **Phase 5: Classroom (Person 4)** - Teachers run classes and assign sets; students join classes via code and see assignments
- [ ] **Phase 6: Quiz / Test (Person 5)** - Teachers generate auto-graded quizzes from a set; students take them; both roles see results
- [ ] **Phase 7: Integration & QA** - The full E2E flow, offline behavior, security rules, and contribution trail are verified together

## Phase Details

### Phase 0: Platform Spike

**Goal**: Prove that Firebase (firebase_core 4.12.1, firebase_auth 6.5.6, cloud_firestore 6.7.1) and sqflite both initialize and work on Android emulator, before any production code depends on that assumption
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: FND-01, FND-03, FND-04 (FND-02 — Windows desktop — withdrawn 2026-07-18; see REQUIREMENTS.md line 15/180 and STATE.md Decisions)
**Success Criteria** (what must be TRUE):

  1. A throwaway spike app launches without crashing on an Android emulator
  2. The spike app opens a local database and writes/reads a row via `sqflite` on Android
  3. The spike app initializes Firebase, signs up a test user via Firebase Auth, and writes/reads one Firestore document on Android

**Plans**: 3 plans

Plans:
**Wave 1**

- [x] 00-01-PLAN.md — Scaffold spike_platform (Android-only), pin Firebase/sqflite deps, Android config (minSdk 23, cleartext debug-only), dummy Firebase options, Firebase Emulator Suite config

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 00-02-PLAN.md — Implement sqlite_service.dart + firebase_service.dart round-trip logic, wire main.dart spike screen (auto-run + re-run buttons)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 00-03-PLAN.md — Regression/credential-hygiene checks, automated Android emulator verification run (captured console log + screenshot), write SPIKE-FINDINGS.md go/no-go verdict

### Phase 1: Shared Foundation

**Goal**: One locked `core/` layer exists — schema, Firestore design, providers, routing, theme, base repository, team docs — so all 5 developers can build features in parallel without diverging or conflicting
**Mode:** mvp
**Depends on**: Phase 0
**Requirements**: FND-05, FND-06, FND-07, FND-08, FND-09, FND-10, FND-11, FND-12
**Success Criteria** (what must be TRUE):

  1. The local SQLite database contains all 18 ERD tables plus sync metadata (`server_id`, `dirty_at`, `synced_at`) on every table, openable on Android
  2. Firestore has all 5 root collections + subcollections defined per `FIREBASE_SCHEMA.md`, with baseline security rules deployed and the Firestore Emulator runnable locally for development
  3. A feature screen can read current user, role, connectivity, and theme from the 7 shared Riverpod core providers without any feature redefining them
  4. The app launches into a 5-tab bottom nav shell via GoRouter, applies the "Academic Precision" light/dark theme, and redirects unauthenticated users to login automatically
  5. A new developer can clone the repo, follow `DEVELOPER_GUIDE.md`/`CONTRIBUTING.md`/`GIT_WORKFLOW.md`/`ENVIRONMENT.md`, and get the app running with the base repository's cache-first read / Firestore-first write pattern understood

**Plans**: TBD
**UI hint**: yes

### Phase 2: Auth, Profile & Admin

**Goal**: Any user can register, log in, manage their own profile and app settings, and admins can fully manage the user base
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06, PROF-01, PROF-02, PROF-03, PROF-04, ADM-01, ADM-02, ADM-03, ADM-04, ADM-05, ADM-06, ADM-07, ADM-08, ADM-09, ADM-10
**Owner**: Person 1
**Screens**: `login_flashly` (Đăng nhập), `ng_k_t_i_kho_n` (Đăng ký), `h_s_student` (Hồ sơ cá nhân), `c_i_t_ng_d_ng` (Cài đặt), Admin — Danh sách user *(to design)*, Admin — Chi tiết user *(to design)*, Admin — Đổi role *(to design)*, Admin — Khoá/Mở + Xoá tài khoản *(to design)*, Admin — Reset mật khẩu user *(to design)*, Admin — Phân quyền truy cập *(to design)* — 10 screens (4 designed + 6 to design)
**Success Criteria** (what must be TRUE):

  1. A new user can register with username/email/password/confirm-password and sees clear errors for a duplicate email, mismatched passwords, or a missing required field
  2. A registered user can log in with email or username, stays logged in across app restarts via SharedPreferences, and can log out back to the login screen; a locked account is blocked at login with a clear error
  3. A user can view their profile (name, email, username, role, status), edit name/phone/address/avatar, and change their password after verifying the current one; theme and language changes persist via SharedPreferences
  4. An admin can list, search/filter, view detail, change role, lock/unlock, delete, and trigger a password-reset email for any user, with confirmation dialogs on destructive actions, and can view/edit the role x permission matrix
  5. A non-admin user attempting to open any Admin screen is blocked

**Plans**: TBD
**UI hint**: yes

### Phase 3: Flashcard Set

**Goal**: Users can create, browse, edit, delete, duplicate, and favorite flashcard sets that Learning Mode, Classroom, and Quiz all build on
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: SET-01, SET-02, SET-03, SET-04, SET-05, SET-06, SET-07, SET-08, SET-09, SET-10, SET-11, SET-12
**Owner**: Person 2
**Screens**: `th_vi_n` (Thư viện), `th_vi_n_flashcard_list` (Thư viện — danh sách thẻ), `t_o_s_a_b_th` (Tạo/Sửa bộ thẻ), `chi_ti_t_b_th` (Chi tiết bộ thẻ), `b_th_y_u_th_ch` (Bộ thẻ yêu thích) — 5 screens
**Success Criteria** (what must be TRUE):

  1. A user can create a set with title, description, and private/public visibility, add multiple two-sided cards to it, and is blocked from saving with an empty title or zero cards
  2. A user can browse the list of available sets and search by keyword, seeing a clear "no results" state when nothing matches
  3. A user can open a set to see full detail plus every card inside; the owner can edit set info and add/edit/delete individual cards, or delete the whole set after confirming
  4. A user can duplicate any visible set into their own independent copy; a non-owner cannot edit or delete a set they don't own
  5. A student can mark/unmark a set as favorite and see a dedicated list of their favorited sets

**Plans**: TBD
**UI hint**: yes

### Phase 4: Learning Mode

**Goal**: Students can study a flashcard set end-to-end — online or offline — and see their memory progress
**Mode:** mvp
**Depends on**: Phase 1 (codes against Auth/Set repository interfaces per the stagger strategy; runs concurrently with Phases 2-3, with concrete implementations wired in via Riverpod as they land)
**Requirements**: LRN-01, LRN-02, LRN-03, LRN-04, LRN-05, LRN-06, LRN-07, LRN-08, LRN-09, LRN-10, LRN-11, LRN-12, LRN-13
**Owner**: Person 3
**Screens**: `trang_ch` (Trang chủ), `trang_ch_dashboard` (Dashboard), `c_u_h_nh_h_c_b_i_updated` (Cấu hình học bài), `h_c_b_i_flashcards` (Học bài — lật thẻ), `h_c_b_i_ielts_vocab_1` (Học bài — biến thể), `ti_p_t_c_bu_i_h_c` (Tiếp tục buổi học — one variant implemented), `k_t_qu_bu_i_h_c` (Kết quả buổi học), `ti_n_h_c_t_p` + `ti_n_h_c_t_p_stats` (Tiến độ học tập), `ti_n_b_th` (Tiến độ bộ thẻ) — 10 screens
**Success Criteria** (what must be TRUE):

  1. A student can pick a set, configure the session (shuffle, which side shows first), and start studying
  2. A student can flip each card, mark it known or unknown, and watch session progress (studied/total, known/unknown counts) update live
  3. If a student exits mid-session, the session state is saved, and resuming brings them back to the exact card where they stopped
  4. After finishing, the student sees a result summary for the session, can reset learning progress for a set, and can review only the cards previously marked unknown
  5. A student with a cached set can study normally with no network connection, and a personal progress dashboard (overall and per-set) reflects completed sessions

**Plans**: TBD
**UI hint**: yes

### Phase 5: Classroom

**Goal**: Teachers can run classes and assign sets to them; students can join classes by code and track what's assigned
**Mode:** mvp
**Depends on**: Phase 1 (codes against Auth/Set repository interfaces per the stagger strategy; runs concurrently with Phases 2-3, with concrete implementations wired in via Riverpod as they land)
**Requirements**: CLS-01, CLS-02, CLS-03, CLS-04, CLS-05, CLS-06, CLS-07, CLS-08, CLS-09, CLS-10, CLS-11, CLS-12, CLS-13, CLS-14, CLS-15, CLS-16
**Owner**: Person 4
**Screens**: `l_p_h_c_student` (Lớp học — Student), `l_p_h_c_teacher` (Lớp học — Teacher), `chi_ti_t_l_p_th_nh_vi_n` (Chi tiết lớp — Thành viên), `chi_ti_t_l_p_b_th` (Chi tiết lớp — Bộ thẻ), `chi_ti_t_l_p_ho_t_ng` (Chi tiết lớp — Hoạt động), `tham_gia_l_p_nh_p_m` (Tham gia lớp — nhập mã), `x_c_nh_n_tham_gia_l_p` (Xác nhận tham gia lớp) — 7 screens
**Success Criteria** (what must be TRUE):

  1. A teacher can create, edit, and delete a class (with confirmation), and sees a list of classes they teach; on creation the system auto-assigns a unique 6-digit join code; a student sees a list of classes they've joined
  2. A user can open a class detail with members/sets/activity tabs; a teacher can see the auto-generated join code and toggle joining on/off (but cannot choose the code themselves), and add or remove members directly
  3. A student can enter a join code to join a class and confirm, with clear errors for a wrong/disabled code or already being a member; a student can leave a class
  4. A teacher can assign a flashcard set to the class with a due date; a student sees assigned sets with their own completion status, and the teacher sees completion progress across the whole class
  5. Both roles can view a chronological activity feed for the class

**Plans**: TBD
**UI hint**: yes

### Phase 6: Quiz / Test

**Goal**: Teachers can generate and publish auto-graded quizzes from a flashcard set; students take them, and both roles see results
**Mode:** mvp
**Depends on**: Phase 1 (codes against Auth/Set repository interfaces per the stagger strategy; runs concurrently with Phases 2-3, with concrete implementations wired in via Riverpod as they land)
**Requirements**: QUZ-01, QUZ-02, QUZ-03, QUZ-04, QUZ-05, QUZ-06, QUZ-07, QUZ-08, QUZ-09, QUZ-10, QUZ-11, QUZ-12, QUZ-13, QUZ-14, QUZ-15
**Owner**: Person 5
**Screens**: `danh_s_ch_b_i_ki_m_tra_teacher` (Danh sách bài KT — Teacher), `danh_s_ch_b_i_ki_m_tra_student` (Danh sách bài KT — Student), `t_o_b_i_ki_m_tra_th_ng_tin_chung` (Tạo bài KT — thông tin chung), `t_o_b_i_ki_m_tra_so_n_c_u_h_i` (Tạo bài KT — soạn câu hỏi), `l_m_b_i_ki_m_tra_c_u_h_i_3_20` (Làm bài kiểm tra), `k_t_qu_b_i_ki_m_tra_student` (Kết quả bài KT — Student), `k_t_qu_b_i_ki_m_tra_l_p` (Kết quả bài KT — Lớp) — 7 screens
**Success Criteria** (what must be TRUE):

  1. A teacher can create a quiz (title, description, time limit, question count, question/answer order), generate MCQ questions from a source set, and edit each question's 4 options with one marked correct
  2. A teacher can save a quiz as draft, archive it, or publish and assign it to a class; teacher and student quiz lists both show the correct status per quiz
  3. A student sees their assigned quizzes, can take one — answering questions, navigating prev/next, watching a countdown timer and progress indicator — and submit it
  4. On submit, the system auto-grades and stores score/total/time; the student sees per-question correct/incorrect results, and cannot retake a submitted quiz
  5. A teacher can view whole-class results for a given quiz

**Plans**: TBD
**UI hint**: yes

### Phase 7: Integration & QA

**Goal**: The five feature modules work together as one product — the full E2E journey, offline behavior, and role-based security all verified, ready to demo on a clean machine
**Mode:** mvp
**Depends on**: Phase 2, Phase 3, Phase 4, Phase 5, Phase 6
**Requirements**: TEAM-01, TEAM-02, TEAM-03, TEAM-04
**Success Criteria** (what must be TRUE):

  1. The full journey runs without manual workarounds: register → login → create a set → study it → generate a quiz from that set → assign the quiz to a class → a student joins the class and takes the quiz → both student and teacher see the results
  2. Disabling the network mid-session and reconnecting shows study progress still works offline against the SQLite cache and syncs correctly once back online
  3. Firestore security rules deny cross-role and cross-user access when tested with student, teacher, and admin identities in the Rules Playground
  4. A reviewer can open the contribution docs and git history and see, via branch names, commit messages, and `lib/features/<module>/` folder ownership, exactly which of the 5 people built which module, with no cross-module imports
  5. The app builds and runs the full journey above on a freshly cloned, clean machine for the Android APK

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 (Phases 2-6 run concurrently once Phase 1 ships)

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 0. Platform Spike | 2/3 | In Progress|  |
| 1. Shared Foundation | 0/TBD | Not started | - |
| 2. Auth, Profile & Admin | 0/TBD | Not started | - |
| 3. Flashcard Set | 0/TBD | Not started | - |
| 4. Learning Mode | 0/TBD | Not started | - |
| 5. Classroom | 0/TBD | Not started | - |
| 6. Quiz / Test | 0/TBD | Not started | - |
| 7. Integration & QA | 0/TBD | Not started | - |
