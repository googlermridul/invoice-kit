import 'package:invoice_kit/core/errors/error_handler.dart';
import 'package:invoice_kit/core/errors/error_mapper.dart';
import 'package:invoice_kit/core/network/interceptors/auth_interceptor.dart';
import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/core/storage/local_storage_service.dart';
import 'package:invoice_kit/core/storage/secure_storage_service.dart';
import 'package:invoice_kit/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:invoice_kit/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/forgot_password_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/login_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:invoice_kit/features/authentication/domain/usecases/register_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockHiveStorageService extends Mock implements HiveStorageService {}

class MockErrorMapper extends Mock implements ErrorMapper {}

class MockErrorHandler extends Mock implements ErrorHandler {}

class MockTokenProvider extends Mock implements TokenProvider {}

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockRegisterUseCase extends Mock implements RegisterUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}
