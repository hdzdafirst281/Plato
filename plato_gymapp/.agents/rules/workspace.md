---
trigger: always_on
---

# Plato Gym App - Architecture & Domain Rules

## 0. Context Routing (CRITICAL RULE)
- Before implementing, analyzing, or modifying ANY code inside `lib/features/{feature_name}`, you MUST silently read the specific `lib/features/{feature_name}/rules.md` file (if it exists). 
- Do NOT mix domain rules between features.

## 1. Core Stack & Libraries
- **Routing**: Strictly use `go_router`. NEVER use `auto_route` or push standard `MaterialPageRoute`. Strictly forbid the use of `auto_route`.
- **State Management**: Use `flutter_bloc` (specifically `Cubit`). Keep state minimal and strictly immutable using `freezed`.
- **Dependency Injection**: Use `get_it` and `injectable`. Always use annotations (`@lazySingleton`, `@injectable`). Never instantiate Repositories or UseCases manually with `new` or `()`.
- **Localization**: Strictly use `slang` for type-safe i18n. ALL strings must use the generated `t` object (e.g. `t.common.save`). NEVER hardcode raw text in the UI. NEVER use string `.tr()`.
- **Database / Backend**: Remote DB is Supabase (`core/network/supabase_module.dart`). Local caching uses SQLite (Floor) in `core/database/`.

## 2. Architecture Enforcements
- **Feature-based Structure**: Strictly adhere to the `lib/features/{feature_name}/` structure containing `data`, `domain`, and `presentation` layers.
- **Separation of Concerns**: UI widgets MUST NOT interact with Repositories directly. The strict flow is: UI (Trigger Event) -> Cubit (Business Logic) -> Repository (Data fetch) -> UI (State rebuild).

## 3. Code Generation & Build Runner
- Whenever modifying classes annotated with `@freezed`, `@JsonSerializable`, `@injectable`, `@dao`, or `@Database`:
  You MUST inform the user or execute the command:
  `dart run build_runner build --delete-conflicting-outputs`
- NEVER edit generated files (`.freezed.dart`, `.g.dart`, `injection.config.dart`, `app_database.g.dart`) manually.

## 4. Media, Worker & Isolate Concurrency
- Any `AudioPlayer`, `VideoPlayerController`, or `AnimationController` MUST be properly initialized and explicitly disposed of in the `dispose()` method.
- `BackgroundWorkoutService` operates on a separated Isolate. Code inside `core/worker/` MUST NOT use `BuildContext`, UI widgets, or uninitialized `get_it` singletons.
- State communication between UI and Background Service MUST strictly pass through `SharedPreferences` reloads or `FlutterBackgroundService().invoke()`. ALWAYS call `await prefs.reload()` before reading state keys inside the background isolate.
## 5. Clean up Temporary Files
- ALWAYS delete all temporary files, scripts, or backup folders (e.g., restore scripts, tmp_history) created during the debugging or coding process once they are no longer needed to maintain a clean workspace.
