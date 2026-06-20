import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:invoice_kit/app/app_config.dart';
import 'package:invoice_kit/core/connectivity/connectivity_service.dart';
import 'package:invoice_kit/core/errors/error_handler.dart';
import 'package:invoice_kit/core/errors/error_mapper.dart';
import 'package:invoice_kit/core/logger/logger.dart';
import 'package:invoice_kit/core/network/dio_client.dart';
import 'package:invoice_kit/core/network/http_api_client.dart';
import 'package:invoice_kit/core/network/interceptors/auth_interceptor.dart';
import 'package:invoice_kit/core/network/interceptors/logging_interceptor.dart';
import 'package:invoice_kit/core/network/interceptors/refresh_token_interceptor.dart';
import 'package:invoice_kit/core/permissions/permissions_service.dart';
import 'package:invoice_kit/core/security/device_integrity_service.dart';
import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:invoice_kit/core/storage/secure_storage_service.dart';
import 'package:invoice_kit/core/theme/theme_bloc/theme_bloc.dart';
import 'package:invoice_kit/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:invoice_kit/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:invoice_kit/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/forgot_password_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/login_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/register_usecase.dart';
import 'package:invoice_kit/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:invoice_kit/features/backup/data/repositories/backup_repository.dart';
import 'package:invoice_kit/features/backup/presentation/bloc/backup_cubit.dart';
import 'package:invoice_kit/features/business_profile/data/repositories/business_profile_repository.dart';
import 'package:invoice_kit/features/business_profile/presentation/bloc/business_profile_cubit.dart';
import 'package:invoice_kit/features/clients/data/repositories/client_repository.dart';
import 'package:invoice_kit/features/clients/presentation/bloc/clients_cubit.dart';
import 'package:invoice_kit/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:invoice_kit/features/fx/data/datasources/fx_remote_datasource.dart';
import 'package:invoice_kit/features/fx/data/repositories/fx_repository.dart';
import 'package:invoice_kit/features/fx/presentation/bloc/fx_cubit.dart';
import 'package:invoice_kit/features/invoices/data/repositories/invoice_repository.dart';
import 'package:invoice_kit/features/invoices/domain/services/pdf_generator.dart';
import 'package:invoice_kit/features/invoices/presentation/bloc/invoices_cubit.dart';
import 'package:invoice_kit/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:invoice_kit/features/quotes/data/repositories/quote_repository.dart';
import 'package:invoice_kit/features/quotes/presentation/bloc/quotes_cubit.dart';
import 'package:invoice_kit/features/recurring/data/repositories/recurring_repository.dart';
import 'package:invoice_kit/features/recurring/presentation/bloc/recurring_cubit.dart';
import 'package:invoice_kit/features/settings/data/repositories/settings_repository.dart';
import 'package:invoice_kit/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:invoice_kit/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:invoice_kit/features/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:invoice_kit/features/subscription/data/repositories/subscription_repository.dart';
import 'package:invoice_kit/features/subscription/domain/entities/subscription_status.dart';
import 'package:invoice_kit/features/subscription/domain/services/entitlement_service.dart';
import 'package:invoice_kit/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Programmatically registers dependencies.
Future<void> configureDependencies({
  required AppConfig config,
  required LocalStorageService localStorage,
}) async {
  // ── App-level singletons ───────────────────────────────────────────────
  sl
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<LocalStorageService>(localStorage)
    ..registerSingleton<SecureStorageService>(SecureStorageService())
    ..registerSingleton<HiveStorageService>(
      await HiveStorageService.initialize(),
    )
    ..registerSingleton<CoreLogger>(CoreLogger(enabled: config.enableLogging))
    ..registerSingleton<ConnectivityService>(
      ConnectivityService()..initialize(),
    )
    ..registerSingleton<PermissionsService>(const PermissionsService())
    ..registerSingleton<DeviceIntegrityService>(const DeviceIntegrityService())
    ..registerSingleton<HttpApiClient>(HttpApiClient())
    ..registerSingleton<ErrorMapper>(const DefaultErrorMapper())
    ..registerSingleton<ErrorHandler>(ErrorHandler(sl<ErrorMapper>()))
    ..registerSingleton<PdfGenerator>(const PdfGenerator())
    ..registerSingleton<EntitlementService>(const EntitlementService())
    ..registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );

  // ── Dio stack ─────────────────────────────────────────────────────────
  final tokenProvider = SecureStorageTokenProvider(sl<SecureStorageService>());
  sl
    ..registerSingleton<TokenProvider>(tokenProvider)
    ..registerSingleton<AuthInterceptor>(
      AuthInterceptor(config: config, tokenProvider: tokenProvider),
    )
    ..registerSingleton<RefreshTokenInterceptor>(
      RefreshTokenInterceptor(
        secureStorage: sl<SecureStorageService>(),
        dio: Dio(BaseOptions(baseUrl: config.apiBaseUrl)),
      ),
    )
    ..registerSingleton<LoggingInterceptor>(
      LoggingInterceptor(
        logger: sl<CoreLogger>().raw,
        enabled: config.enableLogging,
      ),
    )
    ..registerSingleton<DioClient>(
      DioClient.create(
        config: config,
        authInterceptor: sl<AuthInterceptor>(),
        refreshTokenInterceptor: sl<RefreshTokenInterceptor>(),
        loggingInterceptor: sl<LoggingInterceptor>(),
      ),
    )
    ..registerSingleton<Dio>(sl<DioClient>().dio)
    // ── Authentication feature ─────────────────────────────────────────────
    ..registerSingleton<AuthRemoteDataSource>(
      AuthRemoteDataSourceImpl(sl<Dio>()),
    )
    ..registerSingleton<AuthLocalDataSource>(
      AuthLocalDataSourceImpl(
        sl<SecureStorageService>(),
        sl<HiveStorageService>(),
      ),
    )
    ..registerSingleton<AuthRepository>(
      AuthRepositoryImpl(
        remote: sl<AuthRemoteDataSource>(),
        local: sl<AuthLocalDataSource>(),
        errorHandler: sl<ErrorHandler>(),
        tokenProvider: tokenProvider,
      ),
    )
    ..registerSingleton<LoginUseCase>(LoginUseCase(sl<AuthRepository>()))
    ..registerSingleton<RegisterUseCase>(RegisterUseCase(sl<AuthRepository>()))
    ..registerSingleton<LogoutUseCase>(LogoutUseCase(sl<AuthRepository>()))
    ..registerSingleton<ForgotPasswordUseCase>(
      ForgotPasswordUseCase(sl<AuthRepository>()),
    )
    // ── InvoiceKit features ────────────────────────────────────────────────
    ..registerSingleton<BusinessProfileRepository>(
      BusinessProfileRepositoryImpl.create(sl<HiveStorageService>()),
    )
    ..registerSingleton<ClientRepository>(
      ClientRepositoryImpl.create(sl<HiveStorageService>()),
    )
    ..registerSingleton<InvoiceRepository>(
      InvoiceRepositoryImpl.create(sl<HiveStorageService>()),
    )
    ..registerSingleton<QuoteRepository>(
      QuoteRepositoryImpl.create(sl<HiveStorageService>()),
    )
    ..registerSingleton<RecurringRepository>(
      RecurringRepositoryImpl.create(sl<HiveStorageService>()),
    )
    ..registerSingleton<SettingsRepository>(
      SettingsRepositoryImpl(storage: sl<HiveStorageService>()),
    )
    ..registerSingleton<SubscriptionRemoteDataSource>(
      SubscriptionRemoteDataSourceImpl(sl<Dio>()),
    )
    ..registerSingleton<SubscriptionRepository>(
      SubscriptionRepositoryImpl(
        remote: sl<SubscriptionRemoteDataSource>(),
        storage: sl<HiveStorageService>(),
      ),
    )
    ..registerSingleton<FxRemoteDataSource>(FxRemoteDataSourceImpl(sl<Dio>()))
    ..registerSingleton<FxRepository>(
      FxRepositoryImpl(
        remote: sl<FxRemoteDataSource>(),
        storage: sl<HiveStorageService>(),
      ),
    )
    ..registerSingleton<BackupRepository>(
      BackupRepositoryImpl(
        storage: sl<HiveStorageService>(),
        prefs: sl<SharedPreferences>(),
        subscriptionStatus: SubscriptionStatus.initial(),
      ),
    )
    // ── Blocs / cubits ────────────────────────────────────────────────────
    ..registerFactory<AuthBloc>(
      () => AuthBloc(
        loginUseCase: sl<LoginUseCase>(),
        logoutUseCase: sl<LogoutUseCase>(),
        forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
        registerUseCase: sl<RegisterUseCase>(),
        repository: sl<AuthRepository>(),
      ),
    )
    ..registerFactory<OnboardingBloc>(
      () => OnboardingBloc(
        localStorage: sl<LocalStorageService>(),
        businessRepo: sl<BusinessProfileRepository>(),
        settingsRepo: sl<SettingsRepository>(),
        subscriptionRepo: sl<SubscriptionRepository>(),
        entitlements: sl<EntitlementService>(),
      ),
    )
    ..registerFactory<SubscriptionBloc>(
      () => SubscriptionBloc(
        repository: sl<SubscriptionRepository>(),
        entitlements: sl<EntitlementService>(),
      ),
    )
    ..registerFactory<DashboardCubit>(
      () => DashboardCubit(
        invoiceRepo: sl<InvoiceRepository>(),
        clientRepo: sl<ClientRepository>(),
        quoteRepo: sl<QuoteRepository>(),
      ),
    )
    ..registerFactory<BusinessProfileCubit>(
      () => BusinessProfileCubit(repo: sl<BusinessProfileRepository>()),
    )
    ..registerFactory<ClientsCubit>(
      () => ClientsCubit(
        clientRepo: sl<ClientRepository>(),
        invoiceRepo: sl<InvoiceRepository>(),
        quoteRepo: sl<QuoteRepository>(),
      ),
    )
    ..registerFactory<InvoicesCubit>(
      () => InvoicesCubit(
        invoiceRepo: sl<InvoiceRepository>(),
        businessRepo: sl<BusinessProfileRepository>(),
      ),
    )
    ..registerFactory<QuotesCubit>(
      () => QuotesCubit(
        quoteRepo: sl<QuoteRepository>(),
        businessRepo: sl<BusinessProfileRepository>(),
      ),
    )
    ..registerFactory<RecurringCubit>(
      () => RecurringCubit(
        recurringRepo: sl<RecurringRepository>(),
        invoiceRepo: sl<InvoiceRepository>(),
        businessRepo: sl<BusinessProfileRepository>(),
      ),
    )
    ..registerFactory<SettingsCubit>(
      () => SettingsCubit(repository: sl<SettingsRepository>()),
    )
    ..registerFactory<FxCubit>(
      () => FxCubit(repository: sl<FxRepository>()),
    )
    ..registerFactory<BackupCubit>(
      () => BackupCubit(repository: sl<BackupRepository>()),
    )
    ..registerFactory<SplashBloc>(
      () => SplashBloc(
        localStorage: sl<LocalStorageService>(),
        subscriptionRepository: sl<SubscriptionRepository>(),
      ),
    )
    ..registerLazySingleton<ThemeBloc>(
      () => ThemeBloc(sl<LocalStorageService>()),
    );
}
