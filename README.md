# Plato 🏋️‍♂️

![Version](https://img.shields.io/badge/version-1.1.1+9-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-%5E3.11.4-02569B?logo=flutter)

**Plato** is a comprehensive, local-first Flutter fitness application designed to help users plan workouts, track active training sessions, monitor nutrition and body progress, and stay motivated through a robust gamification system (XP and competitive ranks).

Built with a focus on performance, rich UI/UX, and offline capability, Plato ensures your fitness journey is uninterrupted, whether you're at the gym or offline.

---

## 🌟 Key Features

### 🏋️ Workout Tracking
- **Routine Management:** Browse bundled programs, or create, edit, duplicate, and reorder custom routines.
- **Extensive Exercise Library:** Search built-in exercises or create custom ones with notes and media.
- **Advanced Session Player:** Run active workouts with a persistent mini-player, rest timers, supersets, sound cues, vibrations, and background service support.
- **Comprehensive Analytics:** Track workout volume, estimated calories, personal records (PRs), muscle distribution, training load, and recovery metrics.
- **Flexible Set Types:** Record weight/reps, reps-only, timed, distance, and step-based sets. (Limit: 50 unique exercises per session).

### 🥗 Nutrition & Diet
- **Daily Log:** Track meals, calories, protein, carbohydrates, fat, and hydration (water intake).
- **Food Encyclopedia:** Search the bundled food database or save custom foods.
- **Smart Targets:** Automatically calculate nutrition targets based on user profile, goals, and body metrics (with manual override available).
- **History & Analytics:** Copy previous meals and review historical nutrition trends.

### 📈 Profile & Progress
- **Guided Onboarding:** Tailor the app based on body measurements, experience level, environment, schedule, goals, injuries, and diet.
- **Progress Tracking:** Monitor weight changes and activity heatmaps.
- **Advanced Charts:** Visualize training load, muscle recovery, and workout history using interactive charts.
- **Customization:** Light/Dark themes, dynamic scaling, and in-app tutorials (`ShowCaseView`).

### 🎮 Gamification
- **XP & Rewards:** Earn XP and unlock rewards for consistency and personal records.
- **Competitive Ranking System:** Progress through tiers and ranks. Rank calculations and promotions/demotions are handled dynamically via `RankCalculator` (45-day seasons).
- **Rank History:** View historical performance and rank progression.

### 📱 App Experience
- **Responsive Design:** Optimized layouts for Narrow Mobile, standard Mobile, Tablet, and Desktop using `responsive_framework`.
- **Localization:** Multilingual support (Vietnamese and English) powered by `slang`.
- **Background Sync:** Seamless cloud synchronization when online, ensuring data integrity without blocking the UI.

---

## 🛠 Technology Stack

Plato leverages modern Flutter ecosystem tools and architectural patterns to deliver a maintainable and scalable codebase:

| Area | Implementation / Package |
| --- | --- |
| **Framework** | Flutter & Material Design 3 |
| **State Management** | `flutter_bloc` (Cubits) |
| **Routing** | `go_router` (Stateful Multi-tab Shell) |
| **Dependency Injection** | `get_it` & `injectable` |
| **Local Database** | `floor` (SQLite) |
| **Lightweight Storage** | `shared_preferences` |
| **Backend & Auth** | Supabase (`supabase_flutter`) |
| **Data Models** | `freezed` & `json_annotation` |
| **Localization (i18n)** | `slang_flutter` (Type-safe i18n) |
| **Background Tasks** | `workmanager` & `flutter_background_service` |
| **Media & Feedback** | `just_audio`, `video_player`, `vibration`, `lottie` |
| **Charts & Visuals** | `fl_chart`, `flutter_svg`, `shimmer` |

---

## 📂 Project Architecture

The project strictly follows a **Feature-First (Modular)** architecture combined with **Clean Architecture** principles within each feature.

```text
lib/
├── main.dart
├── core/
│   ├── bloc/             # Global App State (e.g., Guided Tours)
│   ├── database/         # Floor DB, DAOs, Entities, and Migrations
│   ├── designsystem/     # Theming, Colors, Shapes, and Reusable UI Components
│   ├── di/               # GetIt and Injectable configurations
│   ├── navigation/       # AppRouter, GoRouter configuration, Global Wrappers
│   ├── network/          # Supabase Client Initialization
│   ├── utils/            # Utilities (Time, Focus, Formatters)
│   └── worker/           # Background Sync and Foreground Workout Services
└── features/
    ├── auth/             # Onboarding, OTP Auth, User Session
    ├── gamification/     # XP, Ranks, Rewards, RankCalculator Domain
    ├── nutrition/        # Food Tracking, Macro Calculation
    ├── profile/          # Settings, Body Metrics, Stats, Calendar
    └── workout/          # Exercise Library, Routine Editor, Active Session Player
```

**Other Important Directories:**
```text
assets/
├── init_data.sql         # Bundled master data (Exercises & Foods)
├── logo/                 # App logos for Splash & Icons
├── lottie/               # Animations
├── svg/                  # Vector graphics (Muscle maps, UI icons)
└── sounds/               # Audio cues for timers

android/ ios/ web/        # Platform-specific native code
test/                     # Automated unit and widget tests
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK:** `^3.11.4`
- **IDE:** Android Studio, IntelliJ, or VS Code
- **Platform Tooling:** Xcode (for iOS), Android SDK (for Android)
- **Supabase Project:** Configured with required tables and RPCs.

### 1. Supabase Environment Setup
Create a `.env` file in the root of the project:
```dotenv
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-public-anon-key
```
> **Warning:** Only put the public `ANON_KEY` in the `.env` file. Never expose your `SERVICE_ROLE` key in the frontend repository.

**Required Supabase Tables:**
`users`, `workout_history`, `routines`, `reward_claims_ledger`, `user_rank_history`

**Required Supabase RPCs (PostgreSQL functions):**
`check_email_exists`, `delete_user_account`, `get_server_time_ms`

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Code Generation
Plato relies heavily on generated code (`injectable`, `floor`, `freezed`, `json_serializable`, and `slang`). 

Run the build runner to generate the necessary files:
```bash
dart run build_runner build --delete-conflicting-outputs
```
*(For active development, use `watch` instead of `build`)*

### 4. Run the Application
```bash
flutter run
```

---

## 🌍 Localization (i18n)

Translations are managed using `slang`. The JSON files are located in:
- `lib/i18n/strings_vi.i18n.json` (Vietnamese - Default)
- `lib/i18n/strings_en.i18n.json` (English)

After modifying translation files, always regenerate the dart code:
```bash
dart run slang
```

---

## 🎨 App Icons & Splash Screen

If you change the logo assets in `pubspec.yaml`, regenerate the native splash screens and icons:
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## ✅ Code Quality & Testing

Format the code, run static analysis, and execute tests:
```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
> **Note:** Mobile-specific features (Foreground Services, Notifications) require testing on physical devices or emulators, and cannot be fully validated via standard Flutter tests alone.

---

## 🧠 Business Logic & Guidelines

Feature-specific rules and logic are documented in their respective domains:
- `lib/features/workout/rules.md`
- `lib/features/gamification/rules.md`

Always keep complex calculation rules in the **Domain Layer** (e.g., `RankCalculator`, `RecoveryCalculator`) rather than polluting Presentation/UI widgets.