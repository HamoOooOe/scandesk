# ScanDesk

QR-based IT asset and ticket management app, built with Flutter and Supabase.

Every company device gets a QR sticker. Employees scan it to report a problem;
IT technicians scan it to see the device's full repair history and log their
work, even offline.

> Status: in development (Sprint 0)

## Features (planned)

- Role-based access: employee, technician, IT manager
- Asset inventory with sites and locations
- QR label generation and scanning
- Tickets with photos and real-time status updates
- Repair history per device
- Push notifications
- Offline-first technician mode
- Manager dashboard

## Tech stack

Flutter · Dart · flutter_bloc · go_router · get_it · Supabase (Postgres, Auth,
Storage, Realtime, Edge Functions) · Drift · Firebase Cloud Messaging

## Architecture

Feature-first Clean Architecture. Each feature has three layers:

- `domain/`: entities and repository contracts (pure Dart)
- `data/`: models and Supabase implementations
- `presentation/`: cubits, pages and widgets

```
lib/
  core/        config, di, router, theme, l10n, errors, shared widgets
  features/    auth, inventory, scan, tickets, history, dashboard, sync
supabase/
  migrations/  database schema as SQL files
  functions/   Edge Functions
```

## Getting started

1. Install Flutter (stable) and run `flutter pub get`.
2. Copy `.env.example` to `.env` and add your Supabase URL and anon key.
3. Run the SQL files in `supabase/migrations/` in the Supabase SQL Editor.
4. `flutter run`

## Screenshots

_Coming soon._

## Hardest problems I solved

_Coming soon._
