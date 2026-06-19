import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invoice_kit/app/app_config.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/services/app_info_service.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:invoice_kit/core/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds a singleton runtime config (set in `bootstrap`).
final RuntimeConfigHolder runtimeConfig = RuntimeConfigHolder();

class RuntimeConfigHolder {
  late AppConfig config;
}

Future<void> bootstrap(Widget Function() builder) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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

      // 5. System UI
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // 6. Run
      runApp(
        BlocProvider<ThemeBloc>(
          create: (_) => ThemeBloc(localStorage),
          child: builder(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught: $error\n$stack');
    },
  );
}
