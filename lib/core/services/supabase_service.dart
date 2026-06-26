import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Convenience accessor for the initialised [sb.SupabaseClient].
///
/// Centralised so tests / mocks can replace it via DI if needed, and so
/// non-feature code doesn't have to know the SDK type.
class SupabaseService {
  SupabaseService(this._client);

  final sb.SupabaseClient _client;

  sb.SupabaseClient get client => _client;

  sb.User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => _client.auth.currentSession != null;

  Stream<sb.AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
