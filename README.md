# Flutter Boilerplate

Production-ready Flutter boilerplate with Clean Architecture, BLoC, GetIt, and GoRouter.

## Highlights

- **Architecture**: Clean Architecture · Feature-First · Repository Pattern
- **State Management**: `flutter_bloc`
- **DI**: `get_it` (manual registration; codegen-ready via `injectable`)
- **Networking**: `dio` with auth, logging, refresh-token, and SSL-pinning hooks
- **Storage**: `shared_preferences`, `hive`, `flutter_secure_storage`
- **Routing**: `go_router` with auth guards and refresh-listener
- **Theme**: Material 3, light/dark/system, persistent via `ThemeBloc`
- **Localization**: English, Bangla, Arabic (extensible)
- **Testing**: unit, widget, integration with `bloc_test` + `mocktail`
- **CI**: GitHub Actions for analyze / test / build APK / AAB / iOS

## Folder Structure

```
lib/
├── app/                # AppConfig, bootstrap, App widget, main entry
├── core/
│   ├── api/            # ApiConstants, Endpoints, Response, Result
│   ├── assets/         # Type-safe asset paths
│   ├── connectivity/   # ConnectivityService
│   ├── constants/      # StorageKeys, AppConstants
│   ├── di/             # GetIt container + injection.config
│   ├── errors/         # Failures + ErrorMapper + ErrorHandler
│   ├── exceptions/     # AppException hierarchy
│   ├── extensions/     # Context, String, DateTime, Iterable
│   ├── localization/   # Locales + AppLocalizations stub
│   ├── logger/         # Logger
│   ├── network/        # DioClient + interceptors + HttpApiClient
│   ├── permissions/    # PermissionsService
│   ├── router/         # AppRouter + route names/paths/guards
│   ├── security/       # SSL pinning + device integrity
│   ├── services/       # AppInfoService
│   ├── storage/        # LocalStorage / Hive / Secure
│   ├── theme/          # Colors / Text / Spacing / ThemeBloc
│   ├── typography/     # Font family / weights / styles
│   ├── utils/          # Formatters / Debouncer / typedefs
│   ├── validators/     # Validators
│   └── widgets/        # Reusable widgets (Loading, Empty, Error)
├── shared/             # App-wide widgets / dialogs / bottom sheets
│                       # extensions / mixins / helpers
└── features/
    ├── splash/
    ├── onboarding/
    ├── authentication/ # Clean Architecture: data/domain/presentation
    ├── home/
    └── settings/
```

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run --dart-define=APP_ENV=development
```

## Environment

Copy the example file and edit:

```bash
cp .env.staging .env.staging.local
```

Available keys: `APP_NAME`, `APP_ENV`, `APP_BASE_URL`, `API_TIMEOUT_SECONDS`,
`ENABLE_LOGGING`, `LOCALE`.

## Tests

```bash
flutter test
flutter test integration_test
```

## Build

```bash
flutter build apk --dart-define=APP_ENV=production
flutter build appbundle --dart-define=APP_ENV=production
flutter build ios --release --no-codesign --dart-define=APP_ENV=production
```

See `docs/git-workflow.md` for branching conventions.
