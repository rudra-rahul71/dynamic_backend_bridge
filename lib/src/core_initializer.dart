import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_repository.dart';
import 'auth/firebase_auth_impl.dart';
import 'auth/supabase_auth_impl.dart';
import 'database/database_repository.dart';
import 'database/firestore_database_impl.dart';
import 'database/supabase_database_impl.dart';
import 'models/app_config.dart';

class DynamicBackendBridge {
  /// Initializes the auth and database implementations dynamically, and registers them
  /// as singletons inside the service locator (GetIt).
  static Future<void> initialize({
    required AppConfig config,
    required GetIt getIt,
    FirebaseOptions? defaultFirebaseOptions,
  }) async {
    // Unregister existing services if they are already registered (for backend hot swaps)
    if (getIt.isRegistered<AuthRepository>()) {
      await getIt.unregister<AuthRepository>();
    }
    if (getIt.isRegistered<DatabaseRepository>()) {
      await getIt.unregister<DatabaseRepository>();
    }

    if (config.backendType == BackendType.supabase) {
      try {
        await Supabase.instance.dispose();
      } catch (_) {}

      await Supabase.initialize(
        url: config.supabaseUrl ?? 'http://localhost:54321',
        anonKey: config.supabaseAnonKey ?? '',
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
    } else {
      final app = await _initializeFirebase(config, defaultFirebaseOptions);
      final auth = FirebaseAuth.instanceFor(app: app);
      final firestore = FirebaseFirestore.instanceFor(app: app);
      getIt.registerSingleton<AuthRepository>(
        FirebaseAuthImpl(firebaseAuth: auth),
      );
      getIt.registerSingleton<DatabaseRepository>(
        FirestoreDatabaseImpl(firestore: firestore),
      );
    }
  }

  static Future<FirebaseApp> _initializeFirebase(
    AppConfig config,
    FirebaseOptions? defaultFirebaseOptions,
  ) async {
    // Ensure the default [DEFAULT] app is initialized first
    try {
      Firebase.app();
    } catch (_) {
      if (defaultFirebaseOptions == null) {
        throw ArgumentError(
          'defaultFirebaseOptions must be provided when initializing Firebase backend in managed mode.',
        );
      }
      if (!_isValidFirebaseOptions(defaultFirebaseOptions)) {
        throw ArgumentError(
          'The default/managed Firebase options are invalid or malformed. App ID: "${defaultFirebaseOptions.appId}"',
        );
      }
      await Firebase.initializeApp(options: defaultFirebaseOptions);
    }

    if (config.backendType == BackendType.byoFirebase) {
      final byoOptions = FirebaseOptions(
        apiKey: config.firebaseApiKey ?? '',
        appId: config.firebaseAppId ?? '',
        messagingSenderId: config.firebaseMessagingSenderId ?? '',
        projectId: config.firebaseProjectId ?? '',
      );

      if (!_isValidFirebaseOptions(byoOptions)) {
        throw ArgumentError(
          'The Custom Firebase options are invalid or malformed. App ID: "${byoOptions.appId}"',
        );
      }

      final customAppName = 'byo_${byoOptions.projectId}';

      try {
        final existingApp = Firebase.app(customAppName);
        return existingApp;
      } catch (_) {}

      return await Firebase.initializeApp(
        name: customAppName,
        options: byoOptions,
      );
    } else {
      return Firebase.app();
    }
  }

  static bool _isValidFirebaseOptions(FirebaseOptions options) {
    return options.apiKey.trim().isNotEmpty &&
        options.projectId.trim().isNotEmpty &&
        options.appId.trim().isNotEmpty;
  }
}
