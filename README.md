# ScanDesk

QR-based IT asset and ticket management app, built with Flutter and Supabase.

Every company device gets a QR sticker. Employees scan it to report a problem;
IT technicians scan it to see the device's full repair history and log their
work. Managers keep the inventory and tickets under control.

> Status: Sprints 1 to 4 built, Sprints 5 to 7 partly built (see below).

## The idea: an inspection tag

The whole app is drawn like the inspection tag on a fire extinguisher.
**Service history is punched into a ring of twelve months** (a hole for every
month a device was worked on), and **a ticket's progress is punched along a row
of stations** (Open, Assigned, In progress, Resolved). A ticket that changed
since you last looked stays lit until you open it.

## Features

- Role-based access: employee, technician, IT manager (Supabase Auth + RLS)
- Assets in sites and locations, with search, filters and infinite scroll
- Auto-generated asset codes (`LAP-0007`) from a database trigger
- QR label per device, printable single label or A4 sheet of 24 (PDF)
- QR scanner that routes by role: employees to "report", technicians to history
- Tickets with photos, priority, assignment, start, resolve and a work log
- Live ticket list (Supabase Realtime), status rules enforced in the app **and** in the database
- Repair history timeline and the punched service ring on every device
- Manager overview: tickets by status, reports per day, most repaired devices
- Arabic and English (RTL), light and dark theme

## Demo mode

No Supabase account needed. The app starts on built-in synthetic data
(38 devices, 2 sites, about 50 tickets) and offers one-tap sign-in as each role:

```
flutter run --dart-define=DEMO=true
```

## Tech stack

Flutter · Dart · flutter_bloc · go_router · get_it · Supabase (Postgres, Auth,
Storage, Realtime, Edge Functions) · mobile_scanner · qr_flutter · pdf/printing ·
fl_chart · connectivity_plus

## Architecture

Feature-first Clean Architecture. Each feature has three layers:

- `domain/`: entities and repository contracts (pure Dart)
- `data/`: models and Supabase implementations
- `presentation/`: cubits, pages and widgets

```
lib/
  core/        config, di, router, theme, l10n, errors, demo data, shared widgets
  features/    auth, users, assets, qr, tickets, dashboard, profile, home
supabase/
  migrations/  database schema as SQL files (0001 to 0003)
  functions/   Edge Functions
```

UI never talks to Supabase directly: UI to Cubit to Repository. Because every
repository is an interface, demo mode swaps in in-memory versions without
changing a single screen.

## Getting started

1. Install Flutter (stable) and run `flutter pub get`.
2. Copy `.env.example` to `.env` and add your Supabase URL and anon key.
3. Run the SQL files in `supabase/migrations/` in order in the Supabase SQL Editor.
4. `flutter run` (or `flutter run --dart-define=DEMO=true` for demo data).

## What is not finished

- **Push notifications (Sprint 5):** the Edge Function is written
  (`supabase/functions/notify-ticket`) but sending needs your own Firebase
  project (`google-services.json` and a service account).
- **Offline-first sync (Sprint 6):** the app shows an offline banner and works
  on its last loaded data; a local database with an outbox is not built yet.

## Screenshots

_Coming soon._

## Hardest problems I solved

_Coming soon._
