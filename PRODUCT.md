# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

- **Employee**: at their desk or on the floor, a device (laptop, printer, phone) is broken. Job: report it fast, with a photo, and see who is fixing it. *(inferred from CLAUDE.md and README)*
- **IT technician**: moving between rooms and sites, often with weak signal. Job: scan a device's QR sticker, read its repair history, log the work, close the ticket. *(inferred)*
- **IT manager**: at a desk. Job: keep the inventory clean, assign tickets, change roles, see what is slow or failing. *(inferred)*

## Product Purpose

ScanDesk is a QR-based IT asset and ticket management app. Every company device gets a QR sticker. Employees scan it to report a problem; technicians scan it to see the device's full repair history and log work, even offline. Success: a problem goes from "my laptop is broken" to a resolved, logged ticket without anyone typing an asset code.

## Positioning

The QR sticker is the interface: one scan routes the user by role to the right screen for that exact device (report for employees, history and work log for technicians, full record for managers). A generic ticket tracker cannot do this because it does not own the physical device identity.

## Operating Context

Devices live in sites and locations (buildings, floors, rooms). Technicians work phone-in-hand, one-handed, in server rooms and corridors. A printable A4 sheet of QR labels is part of the real workflow. Arabic and English are both first-class (RTL).

## Capabilities and Constraints

- Flutter (Material 3), flutter_bloc Cubits, go_router, get_it, Supabase (Auth, Postgres + RLS, Storage, Realtime, Edge Functions).
- Roles: employee, technician, manager. Row-level security decides access.
- Feature-first Clean Architecture; every user-facing string in `app_en.arb` and `app_ar.arb`; Directional widgets so RTL works.
- Sprint plan lives in GitHub issues #13 to #45 (Sprints 2 to 7): assets, sites and locations; QR generate, print, scan; tickets with photos and realtime; work logs and asset history; push notifications; offline-first sync; manager dashboard.
- Undecided: Firebase project for push (needs the user's `google-services.json`); real Supabase data is not reachable from this workspace.

## Brand Commitments

Name: **ScanDesk**. Tagline already in the app: "Scan. Report. Fix." It is a portfolio project for Mohamed Moussa (junior Flutter developer, Egypt); the commit history must show only him, with no AI attribution.

## Evidence on Hand

Working login, register, forgot password, role-based homes and manager role screen (Sprint 1, tag v0.1.0). No real customers, no real device inventory, no analytics. Any inventory shown in screenshots is synthetic demo data and must be labelled as such where a viewer could mistake it for real.

## Product Principles

1. The scan is the shortcut: never make someone type what a sticker already knows.
2. Every screen is one-handed and legible in a dim corridor.
3. A ticket's status is always visible and never ambiguous.
4. Works with bad signal; says plainly what is saved and what is waiting.
5. Each role sees only what their job needs.

## Accessibility & Inclusion

Arabic RTL and English; 48dp touch targets; text scales to 1.3x without clipping; status never carried by color alone.
