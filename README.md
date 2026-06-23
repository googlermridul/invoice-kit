# Invoice Kit Flutter Boilerplate

A production‑ready Flutter starter kit built with **Clean Architecture**, **BLoC**, **GetIt** DI, and **GoRouter**. It provides a solid foundation for rapidly developing feature‑rich, maintainable, and testable mobile applications.

---

## 📖 Overview

- **Clean Architecture** – separates UI, domain, and data layers, making the codebase easy to understand, extend, and test.
- **State Management** – `flutter_bloc` for predictable state containers and event‑driven flows.
- **Dependency Injection** – `get_it` (manual registration, ready for `injectable` code‑gen) keeps dependencies explicit and swappable.
- **Networking** – `dio` with authentication handling, request/response logging, token refresh, and SSL‑pinning hooks.
- **Secure Storage** – `shared_preferences`, `hive`, and `flutter_secure_storage` for different persistence needs.
- **Routing** – `go_router` with auth guards and a refresh listener for dynamic navigation.
- **Theming** – Material 3 with light/dark/system themes, persisted via a dedicated `ThemeBloc`.
- **Localization** – English, Bangla, Arabic out‑of‑the‑box, extensible via Flutter's `gen-l10n`.
- **Testing** – Unit, widget, and integration tests powered by `bloc_test` and `mocktail`.
- **CI/CD** – GitHub Actions for static analysis, test execution, and building APK/AAB/iOS artifacts.

---

## 📂 Folder Structure

```
lib/
├─ app/                 # App bootstrap, configuration, root widget
├─ core/                # Core utilities, services, DI, networking, security
│   ├─ api/            # API constants, endpoints, response models
│   ├─ assets/         # Type‑safe asset references (images, animations, fonts)
│   ├─ connectivity/   # Connectivity monitoring service
│   ├─ constants/      # Global constants (storage keys, app constants)
│   ├─ di/             # GetIt registration + injectables config
│   ├─ errors/         # Failure definitions and error mapping
│   ├─ exceptions/     # Custom exception hierarchy
│   ├─ extensions/     # Dart extensions (String, DateTime, Iterable…)
│   ├─ localization/   # Locale definitions and generation stub
│   ├─ logger/         # Logging abstraction
│   ├─ network/        # Dio client, interceptors, HttpApiClient
│   ├─ permissions/    # Permissions handling abstraction
│   ├─ router/         # GoRouter setup, guards, route names/paths
│   ├─ security/       # SSL pinning, device‑integrity checks
│   ├─ services/       # Miscellaneous services (AppInfo, etc.)
│   ├─ storage/        # Hive, secure storage, shared prefs wrappers
│   ├─ theme/          # Theme definitions, colors, spacing, radius, TextTheme
│   ├─ typography/     # Font families, weight, style helpers
│   ├─ utils/          # Helpers (debouncer, money formatter, typedefs)
│   ├─ validators/     # Input validators
│   └─ widgets/        # Reusable UI components (loading, empty, error)
├─ shared/              # App‑wide widgets, dialogs, bottom sheets, mixins
└─ features/            # Feature‑first modules (splash, onboarding, auth, …)
    ├─ splash/
    ├─ onboarding/
    ├─ authentication/   # Clean‑arch sub‑folders: data / domain / presentation
    ├─ home/
    └─ settings/
```

---

## 🚀 Getting Started

```bash
# Install dependencies
flutter pub get

# Run code generation (injectable, json_serializable, etc.)
dart run build_runner build --delete-conflicting-outputs

# Generate localization files
flutter gen-l10n

# Run the app (development environment)
flutter run --dart-define=APP_ENV=development
```

### Environment variables

Copy the example and adjust values:

```bash
cp .env.staging .env.staging.local
```

Available keys include:
- `APP_NAME`
- `APP_ENV` (development / production)
- `APP_BASE_URL`
- `API_TIMEOUT_SECONDS`
- `ENABLE_LOGGING`
- `LOCALE`

---

## 🧪 Tests

```bash
# Unit & widget tests
flutter test

# Integration tests (requires a connected device/emulator)
flutter test integration_test
```

---

## 📦 Build & Release

```bash
# Android APK
flutter build apk --dart-define=APP_ENV=production

# Android App Bundle (Google Play)
flutter build appbundle --dart-define=APP_ENV=production

# iOS (no code‑sign for CI)
flutter build ios --release --no-codesign --dart-define=APP_ENV=production
```

See `docs/git-workflow.md` for branching conventions and PR guidelines.

---

## 🤝 Contributing

1. Fork the repository.
2. Create a feature branch (`git checkout -b feat/awesome-feature`).
3. Follow the **Clean Architecture** folder conventions.
4. Write tests for new functionality.
5. Open a Pull Request – CI will run analysis, tests, and build artifacts automatically.

---

## 📄 License

This project is open‑source and available under the MIT License.
