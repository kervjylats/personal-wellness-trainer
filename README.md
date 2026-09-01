# Personal Wellness Trainer

A multi-role, white-label wellness practice management platform built with Flutter and Supabase.

---

## What It Does

Personal Wellness Trainer is a configurable mobile + web app platform that lets wellness practitioners (yoga studios, life coaches, nutritionists, sound healers, etc.) run their business in one place. It supports four roles out of the box:

- **Owner** — manages activities, team, finance, settings, and partnerships
- **Partner** — a collaborating practitioner with their own limited view
- **Staff** — employees/instructors with configurable permissions
- **Client** — end users who book, pay, message, and track their progress

The platform is **config-driven** — drop in a new `active_job.json` and the entire app rebrands: terminology, modules, colors, activity fields, and navigation all adapt automatically.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State management | Riverpod |
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
| Navigation | go_router |
| Fonts | Inter, Nunito |

---

## Project Structure

```
lib/
├── config/          # Buyer-level profile configs (starter, licensed, etc.)
├── core/            # Theme, constants, extensions, shared widgets, utils
├── data/            # Models, repositories, data sources (mock + Supabase)
├── engine/          # Auth, config, navigation, permissions, roles, shells
└── modules/         # Feature modules (activity, finance, chat, team, etc.)

assets/
├── config/          # Runtime JSON configs (active_job, platform_identity, etc.)
├── fonts/           # Inter & Nunito font files
└── images/          # App icons and images

supabase/
├── schema.sql       # Full database schema
├── seed.sql         # Seed data for development
└── triggers.sql     # Database triggers and automations

integration_test/    # End-to-end integration tests (12 blocks)
test/                # Unit tests per module + widget smoke test
```

---

## Modules

| Module | Description |
|--------|-------------|
| Activity | Create and manage sessions/classes |
| Finance | Revenue tracking, commissions, transactions |
| Team | Partners, staff, clients — network management |
| Messaging | 1-on-1 and group chat with attachments |
| Scheduling | Slot management and availability |
| Reservations | Client booking system |
| Catalog | Product/service shop |
| Media | Video, audio, PDF content library |
| Reviews | Client review collection |
| Agreements | Marketplace and partnership deals |
| GPS | Location tracking (optional) |
| Delivery Fees | Zone-based delivery configuration |
| Inventory | Stock management |
| Challenges | Group fitness/wellness challenges |
| Homework | Client assignment system |
| Progress | Client progress logging |
| Loyalty | Points and rewards |
| Notifications | In-app notification center |

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.x
- Dart ≥ 3.x
- A Supabase project (see `supabase/schema.sql` to set up the database)

### Run the app

```bash
flutter pub get
flutter run
```

### Run tests

```bash
# Unit + widget tests
flutter test

# Integration tests (requires a connected device or emulator)
flutter test integration_test/app_test.dart
```

---

## Configuration

The active business profile is controlled by `assets/config/active_job.json`. Set the `id` and `label` to match a job type defined in `assets/config/job_types.json`, or leave blank to start fresh.

`assets/config/platform_identity.json` controls the top-level app identity (name, tagline, categories, permissions, upgrade URL).

`assets/config/feature_flags.json` controls optional feature toggles (challenges, homework, loyalty, community feed, etc.).

---

## Development Phases

| Phase | Description |
|-------|-------------|
| 1–9 | Mock data layer — all data comes from in-memory mock sources |
| 10 | Supabase integration — replace each `mock_X_source.dart` with `supabase_X_source.dart` |

Currently on **Phase 9**. Auth is live on Supabase (`supabase_auth_source.dart`). All other sources are mocked and will be replaced in Phase 10.

---

## License

Private — all rights reserved.
