import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:invoice_kit/app/app_config.dart';
import 'package:invoice_kit/core/constants/storage_keys.dart';
import 'package:invoice_kit/core/storage/secure_storage_service.dart';
import 'package:invoice_kit/features/authentication/data/models/auth_session_model.dart';
import 'package:invoice_kit/features/authentication/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Supabase-backed authentication. Adds Google sign-in, password reset,
/// and automatic session refresh on top of the existing email/password
/// auth implemented in `AuthRemoteDataSource` (Dio). The existing
/// `AuthRepository` keeps its session model unchanged; this datasource
/// implements the same surface so callers don't need to care which
/// backend is actually used.
abstract class SupabaseAuthDataSource {
  Future<AuthSessionModel> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  });

  Future<AuthSessionModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthSessionModel?> signInWithGoogle();

  Future<void> sendPasswordReset({required String email});

  Future<void> signOut();

  Future<void> deleteAccount();

  Future<AuthSessionModel?> currentSession();

  /// Updates the `last_login_at` column on the `profiles` table for the
  /// currently signed-in user. Safe to call when no session is active.
  Future<void> touchLastLogin();
}

class SupabaseAuthDataSourceImpl implements SupabaseAuthDataSource {
  SupabaseAuthDataSourceImpl({
    required sb.SupabaseClient client,
    required this._secure,
    required this._config,
  }) : _client = client {
    _sub = client.auth.onAuthStateChange.listen(_handleAuthEvent);
  }

  final sb.SupabaseClient _client;
  final SecureStorageService _secure;
  final AppConfig _config;

  late final StreamSubscription<sb.AuthState> _sub;

  void _handleAuthEvent(sb.AuthState state) {
    final session = state.session;
    if (session == null) {
      _secure.delete(SecureKeys.supabaseAccessToken);
      _secure.delete(SecureKeys.supabaseRefreshToken);
      _secure.delete(SecureKeys.supabaseUserId);
      return;
    }
    _secure.write(SecureKeys.supabaseAccessToken, session.accessToken);
    _secure.write(SecureKeys.supabaseRefreshToken, session.refreshToken ?? '');
    _secure.write(SecureKeys.supabaseUserId, session.user.id);
  }

  @override
  Future<AuthSessionModel> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: name == null || name.isEmpty ? null : {'display_name': name},
    );
    final session = res.session;
    final user = res.user;
    if (session == null || user == null) {
      throw sb.AuthException(
        'Sign-up failed: please check your email and password.',
      );
    }
    // Profile row may not exist yet — upsert to ensure FK / RLS picks it
    // up when downstream features insert subscriptions / devices.
    await _client.from(SupabaseTables.profiles).upsert(
      {
        'id': user.id,
        'email': email,
        'display_name': name,
        'created_at': DateTime.now().toIso8601String(),
        'last_login_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'id',
    );
    return _toModel(session, user);
  }

  @override
  Future<AuthSessionModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final session = res.session;
    final user = res.user;
    if (session == null || user == null) {
      throw sb.AuthException('Invalid email or password.');
    }
    await touchLastLogin();
    return _toModel(session, user);
  }

  @override
  Future<AuthSessionModel?> signInWithGoogle() async {
    // On Android the package name and SHA fingerprint are discovered from
    // `google-services.json`, so we MUST NOT pass a `clientId` here —
    // passing an iOS-style Web client ID triggers the
    // `PlatformException(sign_in_failed, ApiException: 10)` crash.
    //
    // `serverClientId` (the Web OAuth client ID) is required on every
    // platform so that Supabase can exchange the ID token server-side.
    final google = GoogleSignIn(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? (_config.googleIosClientId.isEmpty
                ? null
                : _config.googleIosClientId)
          : null,
      serverClientId: _config.googleWebClientId.isEmpty
          ? null
          : _config.googleWebClientId,
    );

    if (defaultTargetPlatform == TargetPlatform.android &&
        _config.googleWebClientId.isEmpty) {
      throw sb.AuthException(
        'Google sign-in is not configured: GOOGLE_WEB_CLIENT_ID is empty '
        'in .env. See docs/google_signin_setup.md.',
      );
    }

    try {
      final account = await google.signIn();
      if (account == null) {
        throw sb.AuthException('Google sign-in was cancelled.');
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw sb.AuthException(
          'Google sign-in did not return an ID token. '
          'Check serverClientId / google-services.json. '
          'See docs/google_signin_setup.md.',
        );
      }
      final res = await _client.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      final session = res.session;
      final user = res.user;
      if (session == null || user == null) {
        throw sb.AuthException('Google sign-in failed.');
      }
      await _client.from(SupabaseTables.profiles).upsert(
        {
          'id': user.id,
          'email': user.email ?? account.email,
          'display_name': account.displayName,
          'photo_url': account.photoUrl,
          'created_at': DateTime.now().toIso8601String(),
          'last_login_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'id',
      );
      return _toModel(session, user);
    } on PlatformException catch (e, st) {
      // `sign_in_failed` with code 10 is the canonical "DEVELOPER_ERROR"
      // thrown when the SHA fingerprint / package / OAuth client ID does
      // not match what Google Play Services expects. Surface a readable
      // hint to the user.
      debugPrint(
        'GoogleSignIn PlatformException(code=${e.code}, '
        'message=${e.message}): $e\n$st',
      );
      throw sb.AuthException(
        'Google sign-in failed (${e.code}). Verify package name, '
        'SHA-1/SHA-256, and serverClientId — see '
        'docs/google_signin_setup.md.',
      );
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    // Best-effort profile / devices cleanup. The actual user delete
    // happens server-side via RLS / a SQL function (see docs).
    await _client.from(SupabaseTables.devices).delete().eq('user_id', user.id);
    await _client.from(SupabaseTables.profiles).delete().eq('id', user.id);
    await _client.auth.signOut();
  }

  @override
  Future<AuthSessionModel?> currentSession() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      // Try to recover from secure storage / Supabase auto-refresh.
      final stored = await _secure.read(SecureKeys.supabaseAccessToken);
      if (stored == null) return null;
    }
    final s = _client.auth.currentSession;
    final u = _client.auth.currentUser;
    if (s == null || u == null) return null;
    return _toModel(s, u);
  }

  @override
  Future<void> touchLastLogin() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from(SupabaseTables.profiles).upsert(
      {
        'id': user.id,
        'last_login_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'id',
    );
  }

  AuthSessionModel _toModel(sb.Session session, sb.User user) {
    final model = UserModel(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['display_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      emailVerified: user.emailConfirmedAt != null,
    );
    return AuthSessionModel(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      user: model,
    );
  }

  Future<void> dispose() async {
    await _sub.cancel();
  }
}
