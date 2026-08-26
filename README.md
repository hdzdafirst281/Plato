# Plato

Plato is a Flutter fitness application for planning workouts, recording active
training sessions, tracking nutrition and body progress, and rewarding
consistency through XP and competitive ranks.

The application is designed around local-first storage. Core fitness data is
stored in a Floor/SQLite database so that the main tracking experience can work
without a constant network connection. Supabase provides email OTP
authentication and cloud-backed profile, workout-history, and gamification
data.

Current package version: `1.1.1+9`.

## Main features

### Workout tracking

- Browse bundled workout programs and save routines locally.
- Create, edit, duplicate, reorder, and organize custom routines.
- Browse the exercise library and create custom exercises with notes or images.
- Record weight/repetition, repetition-only, timed, distance, and step-based
  exercise sets.
- Run an active workout with workout and rest timers, supersets, vibration,
  sounds, notifications, and a persistent mini-player.
- Calculate workout volume, estimated calories, personal records, muscle
  distribution, training load, and muscle recovery.
- Review workout history and schedule routines on the calendar.
- A routine or session is limited to 50 unique exercises.

### Nutrition

- Track daily meals, calories, protein, carbohydrates, fat, and water.
- Search the bundled food encyclopedia and save custom foods.
- Copy previous meal data and review nutrition history.
- Calculate nutrition targets from the user's profile and goals.

### Profile and progress

- Guided onboarding for body measurements, experience, training environment,
  availability, goals, injuries, and dietary restrictions.
- Track weight measurements and edit calculated or custom nutrition targets.
- View workout history, activity heatmaps, training-load analysis, recovery
  charts, and other progress statistics.
- Configure appearance, language, account settings, and in-app tutorials.

### Gamification

- Award XP and personal-record rewards for training activity.
- Display levels, ranks, rank history, and promotion or demotion progress.
- Rank calculations are handled by `RankCalculator`.
- Rank seasons are defined as 45 days.

### App experience

- Vietnamese and English localization; Vietnamese is currently the default.
- Light and dark themes.
- Responsive layouts for narrow phones, phones, tablets, and desktop-sized
  viewports.
- Android foreground workout service and local workout notifications.
- Background cloud synchronization when a network connection is available.

## Technology

| Area | Implementation |
| --- | --- |
| UI | Flutter and Material |
| State management | `flutter_bloc` with Cubits |
| Navigation | `go_router` with a stateful multi-tab shell |
| Dependency injection | GetIt and Injectable |
| Local database | Floor over SQLite |
| Lightweight local state | SharedPreferences |
| Backend and authentication | Supabase |
| Data classes | Freezed and JSON Serializable |
| Localization | Easy Localization |
| Background work | Workmanager and Flutter Background Service |
| Charts and visuals | FL Chart, Lottie, Flutter SVG, and Shimmer |

## Project structure

```text
lib/
├── main.dart
├── core/
│   ├── bloc/             # Shared application state, including guided tours
│   ├── database/         # Floor entities, DAOs, converters, and migrations
│   ├── designsystem/     # Themes, colors, shapes, and reusable Gym widgets
│   ├── di/               # GetIt and Injectable configuration
│   ├── navigation/       # GoRouter routes, shell, and global workout player
│   ├── network/          # Supabase initialization
│   ├── utils/            # Time, search, focus, and tour utilities
│   └── worker/           # Cloud sync and background workout service
└── features/
    ├── auth/
    │   ├── data/         # User models and authentication repository
    │   └── presentation/ # Splash, onboarding, OTP, and Cubits
    ├── workout/
    │   ├── data/         # Models, repositories, and bundled program seeder
    │   ├── domain/       # Recovery, load, and workout calculations
    │   └── presentation/ # Workout screens, components, and Cubits
    ├── nutrition/
    │   ├── data/         # Nutrition models and repository
    │   ├── domain/       # Nutrition target calculator
    │   └── presentation/ # Nutrition screens, components, and Cubit
    ├── gamification/
    │   ├── data/         # Rank and reward models/repository
    │   ├── domain/       # Rank calculation rules
    │   └── presentation/ # Gamification screens and Cubits
    └── profile/
        ├── domain/       # Profile chart helpers
        └── presentation/ # Profile, settings, calendar, stats, and Cubits
```

Other important directories:

```text
assets/
├── init_data.sql         # Bundled exercise and food seed data
├── translations/        # en.json and vi.json
├── logo/
├── images/
├── videos/
├── sounds/
├── svg/
└── lottie/

android/ ios/ web/ windows/ linux/ macos/  # Flutter platform projects
test/                                      # Automated tests
```

Android and iOS are the primary mobile targets. The repository includes the
standard Flutter desktop and web projects, but mobile-specific features such as
foreground workout tracking, notification permissions, and background services
must be tested separately before treating the other targets as production
ready.

## Application flow

At startup, Plato:

1. Loads `.env` and initializes localization.
2. Initializes background synchronization and workout services.
3. Builds the GetIt/Injectable dependency graph, including Supabase,
   SharedPreferences, and the Floor database.
4. Seeds bundled workout programs when the local program table is empty.
5. Opens the splash route, which directs the user into onboarding,
   authentication, or the main application.

The main application uses four persistent navigation branches:

- Workout
- Nutrition
- Gamification
- Profile

An active workout is owned by a global `ActiveSessionCubit`, allowing its timer
and mini-player to remain available while the user moves between tabs.

## Local data

The database file is named `plato_app_database.db` and currently uses Floor
schema version 6. It contains:

- Exercises and custom exercises
- Foods and custom foods
- Bundled workout programs
- User routines
- Workout history
- Daily nutrition logs
- Scheduled workouts
- Local reward claims

Floor migrations currently cover schema versions 2 through 6. Bundled exercise
and food master data is refreshed independently through the seed version in
`core/di/app_module.dart`.

User profile and body-measurement data are stored in SharedPreferences. Records
that participate in synchronization use states such as `PENDING` and `SYNCED`.

## Supabase requirements

Create a `.env` file in the project root:

```dotenv
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-public-anon-key
```

The current source expects these Supabase tables:

- `users`
- `workout_history`
- `routines`
- `reward_claims_ledger`
- `user_rank_history`

It also calls these PostgreSQL RPC functions:

- `check_email_exists`
- `delete_user_account`
- `get_server_time_ms`

The Supabase schema, policies, triggers, and RPC definitions are not included in
this repository. They must already exist in the configured Supabase project.
The rank and reward flow also depends on the backend returning the fields used
by the repositories and sync worker.

Only put public client configuration in `.env`. Flutter assets are bundled into
the application, and this project currently includes `.env` in its asset list.
Never place a Supabase service-role key, database password, or other private
secret in this file.

## Getting started

### Prerequisites

- Flutter with a Dart SDK compatible with `^3.11.4`
- Android Studio/Android SDK for Android development
- Xcode and CocoaPods for iOS development
- A configured Supabase project matching the requirements above

Check the local Flutter installation:

```bash
flutter doctor
```

### Install and run

```bash
flutter pub get
flutter run
```

The application requires a valid `.env` file before startup. If initialization
fails, the current application displays a critical initialization error screen.

### Generate source files

The repository uses generated code for Injectable, Floor, Freezed, and JSON
serialization. After modifying annotated models, DAOs, the database, or
dependency registrations, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

For continuous generation during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Localization

Translations live in:

- `assets/translations/en.json`
- `assets/translations/vi.json`

When adding a user-facing translation key, add it to both files. The app uses
language-only locale codes and falls back to Vietnamese.

### App icons and splash screen

Configuration is stored in `pubspec.yaml`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Quality checks

Run static analysis and formatting:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
```

Run automated tests:

```bash
flutter test
```

The current `test/widget_test.dart` is still the default Flutter counter test
and does not represent Plato's initialized dependency and navigation flow. It
should be replaced before using the test suite as a release gate.

## Business-rule references

Feature-specific rules are documented in:

- `lib/features/workout/rules.md`
- `lib/features/gamification/rules.md`

Keep calculation rules in the appropriate domain layer rather than duplicating
them in screens or widgets.

## Current implementation notes

- Cloud synchronization explicitly handles the user profile, workout history,
  reward claims, XP, and rank history. Other local entities should not be
  assumed to synchronize across devices unless their repository flow does so.
- The local database and the bundled SQL seed have separate version numbers and
  separate responsibilities.
- Workmanager is currently initialized with debug mode enabled; change that for
  a production release.
- Android uses application ID `vn.zenithas.plato`. The iOS project currently
  retains the placeholder bundle identifier `com.example.platoGymapp`.