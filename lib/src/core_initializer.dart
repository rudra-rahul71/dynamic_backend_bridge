import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_repository.dart';
import 'auth/supabase_auth_impl.dart';
import 'database/database_repository.dart';
import 'database/supabase_database_impl.dart';
import 'models/app_config.dart';

class DynamicBackendBridge {
  /// Initializes Supabase auth and database implementations dynamically, and registers them
  /// as singletons inside the service locator (GetIt).
  ///
  /// For [BackendType.managed], [defaultSupabaseUrl] and [defaultSupabaseAnonKey] will be used.
  /// For [BackendType.customSupabase], the endpoint and key stored in [config] are used.
  static Future<void> initialize({
    required AppConfig config,
    required GetIt getIt,
    String? defaultSupabaseUrl,
    String? defaultSupabaseAnonKey,
  }) async {
    // Unregister existing services if registered (for backend hot swaps)
    if (getIt.isRegistered<AuthRepository>()) {
      await getIt.unregister<AuthRepository>();
    }
    if (getIt.isRegistered<DatabaseRepository>()) {
      await getIt.unregister<DatabaseRepository>();
    }

    try {
      await Supabase.instance.dispose();
    } catch (_) {}

    final String url;
    final String anonKey;

    if (config.backendType == BackendType.managed) {
      url = defaultSupabaseUrl ?? 'http://localhost:54321';
      anonKey = defaultSupabaseAnonKey ?? '';
    } else {
      url = config.supabaseUrl ?? 'http://localhost:54321';
      anonKey = config.supabaseAnonKey ?? '';
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    final client = Supabase.instance.client;
    final sbAuth = SupabaseAuthImpl(client: client);
    getIt.registerSingleton<AuthRepository>(sbAuth);
    getIt.registerSingleton<DatabaseRepository>(
      SupabaseDatabaseImpl(client: client),
    );
  }
}
