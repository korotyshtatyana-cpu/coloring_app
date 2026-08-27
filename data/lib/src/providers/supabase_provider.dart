import 'package:core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider that initializes and exposes the Supabase client.
class SupabaseProvider {
  final AppConfig _config;
  late final SupabaseClient _client;

  /// Creates a provider with the given [_config].
  SupabaseProvider({required this._config});

  /// Initializes Supabase with the configured URL and anon key.
  Future<void> initialize() async {
    await Supabase.initialize(
      url: _config.supabaseUrl,
      publishableKey: _config.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// Returns the initialized Supabase client.
  SupabaseClient get client => _client;

  /// Returns the current authenticated user, if any.
  User? get currentUser => _client.auth.currentUser;
}
