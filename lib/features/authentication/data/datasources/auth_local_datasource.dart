import 'package:invoice_kit/core/storage/hive_storage_service.dart';
import 'package:invoice_kit/core/storage/secure_storage_service.dart';
import 'package:invoice_kit/features/authentication/data/models/auth_session_model.dart';
import 'package:invoice_kit/features/authentication/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheSession(AuthSessionModel session);
  Future<AuthSessionModel?> readSession();
  Future<void> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._secure, this._hive);

  static const _box = 'auth_box';
  static const _key = 'session';

  final SecureStorageService _secure;
  final HiveStorageService _hive;

  @override
  Future<void> cacheSession(AuthSessionModel session) async {
    await _secure.write('access_token', session.accessToken);
    await _secure.write('refresh_token', session.refreshToken);
    final box = await _hive.openBox<Map<dynamic, dynamic>>(_box);
    await box.put(_key, Map<String, dynamic>.from(session.toJson()));
  }

  @override
  Future<AuthSessionModel?> readSession() async {
    final access = await _secure.read('access_token');
    final refresh = await _secure.read('refresh_token');
    if (access == null) return null;
    final box = await _hive.openBox<dynamic>(_box);
    final raw = box.get(_key);
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return AuthSessionModel.fromJson({
        ...map,
        'accessToken': map['accessToken'] ?? access,
        'refreshToken': map['refreshToken'] ?? refresh,
      });
    }
    return AuthSessionModel(
      accessToken: access,
      refreshToken: refresh ?? '',
      user: const UserModel(id: '', email: ''),
    );
  }

  @override
  Future<void> clear() async {
    await _secure.deleteAll();
    final box = await _hive.openBox<dynamic>(_box);
    await box.clear();
  }
}
