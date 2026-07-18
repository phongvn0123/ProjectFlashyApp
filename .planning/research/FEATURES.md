# Feature Landscape: Memocard

**Domain:** Flashcard + Classroom + Quiz learning app for teachers and students
**Researched:** 2026-07-18
**Confidence:** HIGH (verified against Quizlet, Anki, Brainscape; Google Classroom; and auto-grading assessment tools)

---

## Overview

Memocard's core value loop is: **Learn (flashcard) → Test (quiz) → See Progress (student + teacher)**.

All six feature groups below are committed in the SRS. This research categorizes each group's features as table stakes (must-have) vs. differentiators (nice-to-have) vs. anti-features (deliberately excluded per PROJECT.md out-of-scope), enabling the team to cut safely if time runs short.

---

## Feature Groups: Table Stakes vs. Differentiators

### 1. Auth & Profile

**Group Purpose:** Enable user registration, login, identity, and session management.

**Complexity:** LOW  
**Dependencies:** None (foundational layer)  
**Blocks:** All other features (user must be authenticated)

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| User registration (email/password) | Users need an account to use the app | LOW | Firebase Auth handles security |
| User login | Users must return to their account | LOW | Firebase Auth + session token in SharedPreferences |
| User logout | Users expect to exit securely | LOW | Clear session token |
| View user profile | Users want to see their own data (name, email, role) | LOW | Display current user from Firestore |
| Change password | Users expect password reset capability | LOW | Firebase Auth password change API |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Edit profile (name, email) | Personalization and account management | LOW | Update user record in Firestore |
| Profile picture / avatar | Visual identity in classroom | MEDIUM | Avatar can be auto-generated initials (avoid Firebase Storage per scope) |
| Preferred language/theme selection | Localization and dark mode support | MEDIUM | Persist in SharedPreferences |
| "Forgot password" email link | Self-service recovery | MEDIUM | Requires Firebase email verification flow |

#### Anti-Features (Deliberately NOT Building)

| Anti-Feature | Why Tempting | Why Excluded | Alternative |
|--------------|--------------|-------------|-------------|
| OAuth/social login (Google, Facebook) | Reduces friction for users | Out of scope; SRS specifies email/password only | Email/password with password recovery |
| Profile verification badges | Adds credibility signaling | Not needed for course project; overkill | Simple role indicators (teacher/student/admin) |
| User search/discovery | Would be nice for networking | Not in SRS; not core to study loop | Only show class members in classroom context |

---

### 2. Admin (User Management)

**Group Purpose:** Provide system administrators with user management, permission control, and account lifecycle operations.

**Complexity:** LOW (CRUD-heavy)  
**Dependencies:** Auth (must know user identity)  
**Blocks:** None directly; supports system operations

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| View user list (paginated) | Admin must see all users to manage them | LOW | Query all users from Firestore, paginate on client |
| Search/filter users (by name, email, role, status) | Admin needs to find specific users quickly | LOW | Client-side filtering + Firestore queries |
| View user detail (profile, role, account status) | Admin must inspect user state before taking action | LOW | Show selected user's full record |
| Update user role (admin/teacher/student) | Admin controls permissions and access | LOW | Update User.role enum in Firestore |
| Lock/unlock user account (status = locked/active) | Admin must prevent compromised or unauthorized accounts | LOW | Update User.status in Firestore |
| Delete user account | Admin must remove accounts (GDPR, account closure) | MEDIUM | Soft delete (mark inactive) or cascade deletions across sets/sessions/quizzes |
| Reset user password (force new password on login) | Admin recovers locked-out users | MEDIUM | Firebase Admin API (backend) or create temp password pattern |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Bulk user operations (import CSV, bulk lock/unlock) | Saves admin time with large user base | HIGH | Not needed for course project (small scope) |
| User activity log (login times, last active, actions taken) | Audit trail and monitoring | MEDIUM | Track in Firestore but display is secondary |
| Custom role creation | Flexibility for organizations | MEDIUM | Overkill for MVP; stick to fixed roles |
| Email user (send reset link, notifications) | Direct communication channel | MEDIUM | Deferred; assume email via manual process or simple notification |

#### Anti-Features (Deliberately NOT Building)

| Anti-Feature | Why Tempting | Why Excluded | Alternative |
|--------------|--------------|-------------|-------------|
| Bulk password reset via email | Scales admin workflow | Requires backend email service (not in scope) | Manual reset + user instructed to check email |
| User permission matrix (fine-grained per-action) | Detailed access control | Over-engineered; fixed roles sufficient | Keep roles simple: admin/teacher/student |
| Import/sync with external directory (LDAP, Active Directory) | Enterprise integration | Out of scope for course project | Manual registration or spreadsheet-based setup |

---

### 3. Flashcard Set (Content Library)

**Group Purpose:** Enable users to create, organize, and manage collections of flashcards.

**Complexity:** LOW-MEDIUM  
**Dependencies:** Auth (ownership), Flashcard (cards belong to sets)  
**Blocks:** Learning Mode, Quiz, Classroom (assignment)

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Create flashcard set (title, description) | Users must create content | LOW | Insert FlashcardSet record in Firestore |
| List user's sets (owner view) | Users need to organize and find their own sets | LOW | Query sets where User.id = owner_id |
| View set detail (metadata + cards within) | Users must see and review cards | LOW | Fetch set + all child Flashcards |
| Update set (title, description, visibility) | Users expect to edit metadata | LOW | Update FlashcardSet record |
| Delete set | Users must clean up old/unwanted sets | MEDIUM | Cascade delete: set → cards → progress → quiz associations |
| Create individual flashcards (question, answer) | Core content creation | LOW | Insert Flashcard records |
| Edit flashcard (update Q/A) | Users must fix mistakes | LOW | Update Flashcard record |
| Delete flashcard from set | Users must manage set contents | LOW | Delete Flashcard; cascade update session/progress data |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Favorite/unfavorite sets | Users can quickly access frequently-used sets | LOW | Manage FavoriteSet table; show favorites tab in UI |
| Duplicate/remix set (copy someone's set as template) | Saves content creation time; encourages sharing | MEDIUM | Clone set + all cards; update ownership; prompt user to customize |
| Visibility control (private vs. public) | Enables sharing and discovery | MEDIUM | FlashcardSet.visibility enum; public sets visible to others (search/browse) |
| Organize by category/tags | Helps users navigate large libraries | MEDIUM | Add tagging system (Firestore denormalization); filter by tag |
| Search within own sets | Find specific content quickly | LOW | Client-side text search or Firestore full-text |
| Bulk import (paste tab-separated Q/A pairs) | Faster content entry | MEDIUM | Parse input format; create multiple Flashcards in batch |

#### Anti-Features (Deliberately NOT Building)

| Anti-Feature | Why Tempting | Why Excluded | Alternative |
|--------------|--------------|-------------|-------------|
| Upload images/audio to set (Firebase Storage) | Enriches flashcard media | Out of scope (no Firebase Storage budget) | URL-only: user pastes image/audio URL if needed; stored as text link |
| AI-generated flashcards (from text input) | Saves content creation time | Out of scope; requires external API | Manual creation only |
| Collaborative editing (multiple users edit same set) | Enables team content creation | Not in SRS; adds complexity (conflict resolution) | Single owner; can duplicate and improve separately |
| Public flashcard marketplace/community sharing | Builds community | Nice-to-have; focus on classroom use first | Make sets private within classroom only; defer sharing |

---

### 4. Learning Mode (Study Session)

**Group Purpose:** Enable students to study flashcards and track learning progress.

**Complexity:** MEDIUM  
**Dependencies:** Auth, Flashcard Set  
**Blocks:** None (generates progress data for tracking)

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Select flashcard set to study | Students must choose what to study | LOW | List user's available sets; selection triggers session |
| Display flashcard (question side) | Core study mechanic | LOW | Fetch card from set; render question text |
| Flip to answer side | Essential interaction | LOW | Toggle card state; show answer |
| Mark card as known/unknown | Fundamental feedback loop | LOW | Update CardProgress.status; immediate feedback |
| Complete study session | Session must have an end state | LOW | Mark LearningSession.status = completed; record end time |
| View session result (summary) | Students expect to see what they learned | MEDIUM | Calculate known/unknown counts; show on result screen |
| View progress over time (past sessions, cumulative stats) | Users want evidence of improvement | MEDIUM | Query CardProgress + LearningSession for user; visualize charts |
| Resume interrupted session (continue where left off) | Users expect to pause and return | MEDIUM | Store LearningSession.status = in_progress; allow re-open and continue |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Multiple study modes (e.g., matching, MC, type-to-answer) | Variety keeps studying engaging | HIGH | Implement alternative card presentation modes; requires UI per mode |
| Review unknown cards (focus on weak areas) | Improves retention; user can drill gaps | MEDIUM | Query CardProgress.status = unknown; show as separate session |
| Shuffle card order | Prevents memorization of position | LOW | Shuffle array before rendering |
| Study streak tracking (days studied) | Gamification; motivation | LOW | Track dates of completed sessions; calculate consecutive days |
| Estimated time to complete (ETC) | Helps users plan study time | LOW | Multiply card count by avg time per card |
| Progress visualization (pie chart, bar chart) | Shows learning at a glance | MEDIUM | Use charts library to visualize known/unknown ratio |

#### Anti-Features (Deliberately NOT Building)

| Anti-Feature | Why Tempting | Why Excluded | Alternative |
|--------------|--------------|-------------|-------------|
| Spaced repetition algorithm (SM-2, Anki) | Scientifically proven retention boost | Out of scope (PROJECT.md); too complex for MVP | Simple known/unknown tracking; review unknown on demand |
| Adaptive difficulty (harder cards shown more) | Personalizes learning | Out of scope; requires algorithm | Fixed presentation order; user decides review strategy |
| Time limits on cards (Pomodoro mode) | Focuses attention; prevents overthinking | Not in SRS; can add later if engagement data supports | Open-ended card study with optional timer widget |
| Timed quiz mode (count-down timer) | Simulates test conditions | Separate from study mode; quiz has this if needed | Study mode is for learning (no timer); quiz is for testing (has timer) |

---

### 5. Classroom (Teacher Class Management)

**Group Purpose:** Enable teachers to organize students into classes, assign content, and track participation.

**Complexity:** MEDIUM  
**Dependencies:** Auth, Flashcard Set (to assign)  
**Blocks:** Quiz assignment pathway (assignments go to classes)

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Create classroom (teacher action) | Teachers must set up class containers | LOW | Insert Classroom record; set teacher as owner |
| View class list (teacher's classes) | Teacher needs to see all their classes | LOW | Query Classroom where teacher_id = current user |
| View class detail (metadata, member list, assignments) | Teacher needs class overview | LOW | Fetch class record + member list + assignment list |
| Update classroom (name, description) | Teacher wants to edit class info | LOW | Update Classroom record |
| Delete classroom | Teacher wants to clean up old classes | MEDIUM | Soft delete or cascade cleanup (members, assignments, sessions, quizzes) |
| Generate class join code (invite students) | Frictionless student onboarding | LOW | Generate random code; store in Classroom record; display to teacher |
| Join class via code (student action) | Students must enter class without teacher manual add | MEDIUM | Validate code; create ClassMember record; add to class |
| Leave class (student action) | Student should be able to exit | LOW | Delete ClassMember record |
| View class members (student list) | Teacher must see who's enrolled | LOW | Query ClassMember records; display names + student info |
| Add/remove members (teacher bulk add) | Teacher controls enrollment | LOW | Insert/delete ClassMember records |
| Assign study set to class | Core teacher action: "everyone study this deck" | MEDIUM | Create AssignedSet record; link FlashcardSet to Classroom |
| View assigned sets (student sees what teacher assigned) | Students must know what to study | LOW | Query AssignedSet for classroom + user can study from assignment |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Class activity feed (notifications log) | Teacher sees engagement: "who studied what when" | MEDIUM | Log events (AssignmentProgress, LearningSession) to ClassActivity; display feed |
| Member roles within class (owner/teacher/TA/student) | Fine-grained permissions | MEDIUM | Add role enum to ClassMember; enforce in quiz view |
| Class announcements/pinned messages | Teacher broadcasts to class | MEDIUM | Add Announcement table; display on class detail |
| Download class roster (export CSV) | Administrative ease | LOW | Generate CSV from member list |
| Class performance analytics (aggregate progress) | Teacher sees who's struggling | MEDIUM | Aggregate CardProgress + QuizAttempt for class; display charts |

#### Anti-Features (Deliberately NOT Building)

| Anti-Feature | Why Tempting | Why Excluded | Alternative |
|--------------|--------------|-------------|-------------|
| Bulk student import (CSV file upload) | Scales enrollment | Out of scope; add manually or use join codes | Join code for student self-enrollment; manual teacher add if needed |
| Assignment scheduling (sets due date, deadline) | Enforces participation | SRS not detailed; add if time permits | Assign immediately; no deadline enforcement in v1 |
| Peer-to-peer interaction (students message each other) | Community building | Out of scope; focus on teacher-led flow | One-way classroom notifications only |
| Sync with school SIS (PowerSchool, Infinite Campus) | Enterprise integration | Out of scope for course project | Manual class creation + invite codes |
| Auto-enroll from roster file | Setup convenience | Out of scope; manual enrollment | Teacher adds students via UI or join code |

---

### 6. Quiz/Test (Assessment & Auto-Grading)

**Group Purpose:** Enable teachers to create quizzes from flashcard sets and students to take them with automatic grading.

**Complexity:** MEDIUM-HIGH  
**Dependencies:** Auth, Flashcard Set (source of questions), Classroom (for assignment)  
**Blocks:** None (but results feed into progress tracking)

#### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Create quiz from flashcard set (select questions, convert to quiz) | Teacher must compose assessments from content | MEDIUM | Create Quiz + QuizQuestion records; link to source FlashcardSet |
| Update quiz (edit title, description, questions) | Teacher wants to revise before publish | MEDIUM | Modify Quiz + QuizQuestion; prevent modification after students start |
| Publish quiz (draft → published state) | Quiz must be released to students | LOW | Update Quiz.status = published; make visible to students |
| Archive quiz (old/unused quizzes) | Teacher wants to clean up without deleting | LOW | Update Quiz.status = archived; hide from main view |
| List quizzes (teacher view) | Teacher needs to manage assessments | LOW | Query Quiz where teacher_id = current user |
| Student takes quiz (attempt, answer questions) | Core student action | MEDIUM | Create QuizAttempt; record QuizAnswer for each question |
| Submit quiz (student action) | Student must formally finish and submit | LOW | Mark QuizAttempt.status = submitted; trigger auto-grade |
| Auto-grade multiple-choice quiz (4-choice options) | Eliminates manual grading | MEDIUM | Compare QuizAnswer.selected_option with QuizOption.is_correct; calculate score |
| View own quiz result (student sees their score + answers) | Student feedback | MEDIUM | Display score, answered questions, compare to correct answers |
| View class quiz results (teacher sees all students' attempts) | Teacher monitors class performance | MEDIUM | Aggregate QuizAttempt scores; show per-student breakdown |
| Assign quiz to class (teacher sends to students) | Quiz deployment mechanism | LOW | Create QuizAssignment record linking Quiz + Classroom |
| Track quiz attempt status (in_progress, submitted, expired) | Know which students have completed | LOW | Query QuizAttempt.status for class |

#### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Randomize question order (shuffle for each attempt) | Prevents memorization | LOW | Shuffle quiz questions before presenting to student |
| Randomize answer options (shuffle choices A/B/C/D) | Prevents pattern recognition | MEDIUM | Shuffle QuizOption order per question; track selected position + remapped value |
| Time limit on quiz (countdown timer) | Simulates test conditions; prevents cheating | MEDIUM | Track start time; enforce end time; warn before expiry |
| Per-question feedback (show explanation after answer) | Educational value | MEDIUM | Store QuizQuestion.explanation; display after student submits |
| Partial credit grading (partial points for partial-credit questions) | Nuanced scoring | MEDIUM | Support QuizOption.points (not just is_correct boolean); sum points |
| Detailed analytics (question difficulty, discrimination) | Identify problematic questions | HIGH | Analyze attempt distribution across options; show stats per question |
| Custom grading scale (%, letter grades, custom scale) | Institutional flexibility | LOW | Configurable on quiz or classroom level |
| Question bank (create quiz from scratch, not just flashcard set) | Decouples assessment from study | MEDIUM-HIGH | Full quiz editor; manually add questions; not linked to flashcard set |

#### Anti-Features (Deliberately NOT Building)

| Anti-Feature | Why Tempting | Why Excluded | Alternative |
|--------------|--------------|-------------|-------------|
| Essay/free-text questions (requires manual grading) | Assesses higher-order thinking | Out of scope (auto-grade requires 4-choice MCQ only) | MCQ only; essay feedback via comments post-submission |
| AI-generated quiz (auto-create from text) | Saves teacher time | Out of scope; no external API budget | Manual quiz creation from flashcard set |
| Plagiarism detection (Turnitin integration) | Academic integrity | Out of scope; not relevant to MCQ | N/A (MCQ is not plagiarizable) |
| Timed retakes (allow multiple attempts with interval) | Measures learning improvement | Not in SRS; overkill for v1 | Single submission; allow re-attempt if teacher manually creates new instance |
| Item analysis & psychometric reports | Assessment research | Out of scope for course project | Basic score aggregation only |
| Rubric-based grading (for essay/subjective) | Consistency in manual grading | Out of scope (no essays) | N/A |

---

## Feature Dependencies

```
Auth & Profile (foundational)
    ├──required by──> Admin (user CRUD)
    ├──required by──> Flashcard Set (ownership)
    ├──required by──> Learning Mode (student identity)
    ├──required by──> Classroom (teacher/student role)
    └──required by──> Quiz (student identity + grading)

Flashcard Set
    ├──required by──> Learning Mode (content to study)
    ├──required by──> Quiz (source of questions)
    └──required by──> Classroom (content to assign)

Learning Mode
    └──generates──> Progress data (CardProgress)
                       └──consumed by──> Session results view

Classroom
    ├──enables──> Assignment flow (AssignedSet)
    ├──required by──> Quiz assignments (quiz → class)
    └──feeds──> Class activity log

Quiz
    ├──generates──> Quiz attempts (QuizAttempt + QuizAnswer)
    ├──requires──> Auto-grade logic (score calculation)
    └──produces──> Student + teacher results views
```

### Dependency Notes

- **Auth blocks everything:** User must be authenticated before any other feature.
- **Flashcard Set blocks Learning + Quiz:** Without flashcards, there's nothing to study or test.
- **Classroom enables assignment:** Quiz and study sets must be assigned to classes; solo study doesn't need a class.
- **Learning Mode and Quiz are parallel:** Students can study independently or take quizzes independently; they don't strictly depend on each other (but together create the loop).
- **Admin is orthogonal:** Admin operations don't block user features; they support system health.

---

## Feature Groups: Complexity & Implementation Order

| Group | Complexity | Build Order | Why |
|-------|-----------|-------------|-----|
| Auth & Profile | LOW | **1st** | Foundational; every other feature depends on it |
| Flashcard Set | LOW | **2nd** | Content creation; learning mode and quiz depend on it |
| Learning Mode | MEDIUM | **3rd** (can run in parallel with Classroom) | Core study loop; demonstrates core value |
| Classroom | MEDIUM | **3rd** (can run in parallel with Learning Mode) | Enables teacher workflow; enables assignment pathway |
| Quiz/Test | MEDIUM-HIGH | **4th** | Depends on Flashcard + Classroom; completes the loop |
| Admin | LOW | **Parallel (anytime)** | Pure CRUD; no blocking dependencies; safe to build alongside others |

---

## MVP Definition

### Launch With (v1 — Course Project Completion)

**Table stakes only. Must have or the demo fails:**

- [x] Auth: Register, login, logout, view profile, change password
- [x] Flashcard Set: Create, list, view, update, delete, create/edit/delete cards
- [x] Learning Mode: Select set, study (flip + mark known/unknown), view session result, view progress
- [x] Classroom: Create, list, view detail, generate join code, join via code, view members, assign set, view assigned sets
- [x] Quiz: Create quiz from flashcard set, publish, student takes & submits, auto-grade MCQ, view own result, teacher views class results
- [x] Admin: User list, search, view detail, lock/unlock, reset password (to support teacher classroom management)

**MVP success criteria:**
- Core loop works: **Learn flashcard → Take quiz from same set → See both student + teacher results**
- All 5 team members can demonstrate their assigned feature group (≥4 screens each)
- Runs on both Android emulator and Windows desktop
- Uses Firestore (online) + SQLite cache (offline)
- No crashes on happy path

### Add After MVP Validation (v1.x — Future Enhancement)

Features to add once core is working and team gets user feedback:

- [ ] Favorite/unfavorite sets (LOW effort; high engagement value)
- [ ] Duplicate/remix flashcard sets (MEDIUM effort; enables content remix)
- [ ] Resume interrupted session (MEDIUM effort; improves UX)
- [ ] Review unknown cards (MEDIUM effort; learning value)
- [ ] Class activity feed (MEDIUM effort; teacher insight)
- [ ] Shuffle card order during study (LOW effort; prevents rote memorization)
- [ ] Study mode visualization (progress pie chart) (MEDIUM effort; motivation)
- [ ] Randomize quiz questions/options (MEDIUM effort; test integrity)
- [ ] Time limit on quiz (MEDIUM effort; realism)

### Future Consideration (v2+ — Post-Course)

Features to defer until product-market fit is established:

- [ ] Spaced repetition algorithm (HIGH effort; scientific retention boost; requires algorithm design + testing)
- [ ] Multiple study modes (games, matching, type-to-answer) (HIGH effort; variety but not core to loop)
- [ ] Public flashcard marketplace (HIGH effort; platform effects)
- [ ] Mobile push notifications (HIGH effort; FCM not compatible with Windows; use in-app only)
- [ ] Image/audio upload to Firebase Storage (MEDIUM effort; budget and scope concerns)
- [ ] Bulk CSV import (MEDIUM effort; enterprise feature)
- [ ] AI-generated quizzes (HIGH effort; requires external API)
- [ ] Plagiarism detection (N/A for MCQ; essay support out of scope)

---

## Suggested Cut Order (If Time Runs Short)

**Priority ranking for de-scoping, in order of first to cut:**

1. **Admin user detail view customization** (display only essentials; remove fancy formatting)
2. **Class activity feed** (defer notifications; show assigned sets only)
3. **Admin bulk user operations** (no CSV import; manual one-by-one management)
4. **Duplicate/remix flashcard sets** (users create from scratch instead)
5. **Resume interrupted session** (force fresh start each time; treat as simpler workflow)
6. **Review unknown cards section** (remove; users can study full deck again)
7. **Randomize quiz questions** (fixed order; no shuffling)
8. **Quiz time limits** (untimed for v1; can add timer later)
9. **Class performance analytics** (hide aggregate stats; show pass/fail only)
10. **Profile picture/avatar** (remove; show initials only)

**Avoid cutting:**
- Core CRUD for any feature group (sets, quizzes, classes)
- Auto-grading logic (core value proposition)
- Session results views (both student and teacher must see results)
- Classroom join code flow (essential for teacher-led setup)

---

## Feature Completeness vs. Competition

| Feature | Quizlet | Anki | Brainscape | Memocard MVP | Assessment |
|---------|---------|------|-----------|-------------|------------|
| Flashcard create/study | ✓ | ✓ | ✓ | ✓ | Table stakes |
| Spaced repetition | Downplayed | ✓ | ✓ | ✗ (out of scope) | Differentiator |
| Multiple study modes | ✓ | Limited | Limited | ✗ (v1.x) | Differentiator |
| Classroom management | Limited | ✗ | ✗ | ✓ | **Memocard differentiator** |
| Auto-grading quizzes | ✓ | Limited | Limited | ✓ | **Memocard differentiator** |
| Progress tracking | ✓ | ✓ | ✓ | ✓ | Table stakes |
| Mobile + desktop | ✓ | Limited | ✓ | ✓ | Table stakes |

**Memocard's competitive edge:** Integrated classroom + auto-graded quiz flow (Quizlet lacks strong teacher LMS; Anki/Brainscape lack classroom).

---

## Research Sources

- [Choosing the Best Flashcard App: Anki, Quizlet, Brainscape Comparison](https://alliedunin.medium.com/anki-vs-quizlet-vs-brainscape-which-flashcard-app-is-the-best-570f2d3d176f)
- [Essential Flashcard App Features Review](https://www.flashcardlab.co/blog/choosing-the-best-flashcard-app-a-thorough-review-of-anki-quizlet-flashcard)
- [Google Classroom Features & Grading Guide](https://developers.google.com/workspace/classroom/guides/key-concepts/grades)
- [Classroom Management Tools & Resources](https://edu.google.com/intl/ALL_us/workspace-for-education/products/classroom/)
- [Auto-Grading Test Creation Tools](https://onlineexammaker.com/kb/top-10-auto-grading-test-creator-for-teachers/)
- [Student Engagement Features in Learning Apps](https://www.europeanbusinessreview.com/core-features-of-student-engagement-apps/)
- [Study Progress Tracking Features](https://www.codemonkey.com/blog/5-apps-to-keep-track-of-your-study-progress/)

---

*Feature research for Memocard flashcard + classroom + quiz app*  
*Researched: 2026-07-18*  
*For roadmap phase definition and team work split*
