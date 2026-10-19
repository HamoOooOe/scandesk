# ScanDesk — notes for Claude Code

## About the project
ScanDesk is a QR-based IT asset and ticket management app built with Flutter + Supabase.
It's a **portfolio project** for Mohamed Moussa, who is applying for **junior Flutter developer** jobs in Egypt.
He is learning as he builds: **explain what you do and why**, in simple terms, so he can explain every line in an interview.

- Repo: https://github.com/HamoOooOe/scandesk (username uses capital letter **O**, not zero)
- Board: GitHub Project "ScanDesk" (Backlog → Todo → In Progress → Review → Done). New issues land in Backlog.
- Milestones S1–S7, labels `feature`, `learning`, `chore`, `sprint-1`…`sprint-7`.
- One-week sprints, Saturday → Friday. Sprint 1 = issues #1–#11, milestone "S1 · Auth + roles", due 30 Oct 2026.

## Stack
Flutter (Material 3) · flutter_bloc (Cubit) · go_router · get_it · Supabase (Auth, Postgres + RLS, Storage, Realtime, Edge Functions) · flutter_dotenv · Arabic + English (gen-l10n, RTL) · tests with bloc_test + mocktail.
Later sprints: mobile_scanner, qr_flutter, pdf/printing, image_picker, FCM, Drift (offline), fl_chart.

## Architecture (feature-first Clean Architecture)
```
lib/core/       config, di (get_it), router (go_router), theme, l10n, errors, widgets
lib/features/<feature>/domain/        entities + repository interfaces (pure Dart)
lib/features/<feature>/data/          models (fromJson/toJson) + Supabase implementations
lib/features/<feature>/presentation/  cubit/, pages/, widgets/
supabase/migrations/                  every SQL change as a numbered file
test/                                 mirrors lib/
```
Rules: UI never talks to Supabase directly (UI → Cubit → Repository). Repositories throw `Failure`s from `core/errors/failures.dart`. Every user-facing string goes in `lib/core/l10n/app_en.arb` **and** `app_ar.arb`. Use Directional widgets/padding so RTL works.

## Current state (end of Sprint 0)
- The app opens on a Sprint 0 home screen (Supabase status, theme + language toggles, shared widgets). **No login is wired yet.**
- Auth code already exists in `lib/features/auth/` (domain, data, AuthCubit, login/splash pages) but is **unplugged**.
- Search the project for `TODO(S1)`: `core/di/injection.dart`, `core/router/app_router.dart`, `app.dart` show exactly where to plug auth in.
- `supabase/migrations/0001_create_profiles.sql` is written but **not yet run** in Supabase.

## Sprint 1 goal
Users can sign up, log in, stay logged in, and land on a home screen that matches their role (employee / technician / manager).
Done when: three test accounts (one per role) each land on a different home screen, and a logged-out user cannot open any inner screen.

Issues: #1 learning (Supabase Auth, triggers, RLS) · #2 profiles table + trigger + RLS · #3 wire auth into DI/router/app · #4 login · #5 register · #6 forgot password · #7 session persistence · #8 router redirects by auth + role · #9 three role-based homes · #10 manager screen to change roles · #11 tests for AuthCubit + AuthRepository.

## Git workflow (always follow this)
- Never commit directly to `main` (it is protected) or `dev`.
- For each issue: `git checkout dev && git pull` → `git checkout -b feature/<short-name>` → small commits → push → open a PR **into `dev`** with `Closes #<issue>` in the body → merge after Mohamed reviews.
- Commit messages: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.
- Before every commit: `flutter analyze` (zero issues) and `flutter test` (all pass).
- **Never commit `.env`** or any key. Only the Supabase publishable/anon key goes in `.env`; never the secret/service_role key.
- Move the issue's card to In Progress when starting and Review when the PR is open.
- End of sprint: PR `dev` → `main`, tag `v0.<sprint>.0`.

## Working style
- Explain each change briefly and point out what Mohamed should understand for interviews.
- Ask before running anything that changes the Supabase database or GitHub settings.
- Keep `DEVLOG.md` updated: 3 lines per session (did / next / blocked).
