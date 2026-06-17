import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_boilerplate/app/app_config.dart';
import 'package:flutter_boilerplate/core/di/injection.dart';
import 'package:flutter_boilerplate/core/services/app_info_service.dart';
import 'package:flutter_boilerplate/core/storage/local_storage_service.dart';
import 'package:flutter_boilerplate/core/theme/theme.dart';
import 'package:flutter_boilerplate/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds a singleton runtime config (set in `bootstrap`).
final RuntimeConfigHolder runtimeConfig = RuntimeConfigHolder();

class RuntimeConfigHolder {
  late AppConfig config;
}

/// Application bootstrap. Wires up env, storage, DI, services, then runs the
/// app.
Future<void> bootstrap(Widget Function() builder) async {
  // 1. Environment
  await dotenv.load(fileName: '.env');
  final config = AppConfig.fromEnv();
  runtimeConfig.config = config;

  // 2. Storage
  await Hive.initFlutter();
  final prefs = await SharedPreferences.getInstance();
  final localStorage = LocalStorageService(prefs);

  // 3. Services
  final appInfo = AppInfoService(localStorage);
  await appInfo.load();

  // 4. DI
  await configureDependencies(config: config, localStorage: localStorage);

  // 5. Auth hydration
  final authBloc = sl<AuthBloc>()..add(const AuthStarted());

  // 6. Run
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      runApp(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<ThemeBloc>(create: (_) => ThemeBloc(localStorage)),
          ],
          child: builder(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught: $error\n$stack');
    },
  );
}
