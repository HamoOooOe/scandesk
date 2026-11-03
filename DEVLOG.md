# Dev log

Three lines before every session: what I did last time, what I'll do now, what's blocking me.
At the end of each sprint: what went well, what slowed me down, what I'll change.

## Sprint 0 · Setup + Supabase from zero

### 2026-10-18
- Did: created the Flutter project and the base architecture (core + auth skeleton).
- Next: run `flutter pub get`, create the Supabase project, fill `.env`, run on my phone.
- Blocked: nothing.

## Sprint 1 · Auth + roles

### 2026-10-19
- Did: ran the profiles migration in Supabase; built #3 auth wiring, #4 login, #5 register, #6 forgot password, #7 session persistence, #8 role redirects, #9 role homes, #10 manager role screen, #11 repository tests (PRs #46-#56, 39 tests pass).
- Next: merge the PRs in order (#46 to #56), then test with three real accounts (employee / technician / manager). Set the first manager by hand in the SQL Editor.
- Blocked: setting a new password from the reset email needs a deep link (not built yet). Email confirmation settings in Supabase may affect sign-up.

## Sprints 2 to 4 · Assets, QR and tickets

### 2026-11-03
- Did: new inspection-tag design system (punch ring, punch track, status tags); assets with sites/locations, QR labels and scanner, tickets with photos and live status, manager overview; demo mode with seeded data; migrations 0002 and 0003.
- Next: run migrations 0002 and 0003 in Supabase, test with the three real accounts; build offline sync (Sprint 6); finish push notifications once the Firebase project exists.
- Blocked: push notifications need my own Firebase project (google-services.json).
