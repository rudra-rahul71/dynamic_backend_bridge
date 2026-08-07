import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/supabase_auth_impl.dart';
import 'database/supabase_database_impl.dart';
import 'models/app_config.dart';
import 'services/notification_service.dart';
import 'services/remote_notification_service.dart';
import 'providers/core_providers.dart';

class DynamicBackendBridge {
  /// Initializes Supabase auth and database implementations dynamically, and returns
  /// a list of Riverpod [Override]s to be injected into the [ProviderScope].
  ///
  /// For [BackendType.managed], [defaultSupabaseUrl] and [defaultSupabaseAnonKey] will be used.
  /// For [BackendType.customSupabase], the endpoint and key stored in [config] are used.
  static Future<List<Override>> initialize({
    required AppConfig config,
    String? defaultSupabaseUrl,
    String? defaultSupabaseAnonKey,
    String dbSchema = 'public',
    String defaultNotificationChannelId = 'default_channel',
    String defaultNotificationChannelName = 'Default Notifications',
    String defaultNotificationChannelDesc = 'Default app notifications',
    String defaultAndroidIcon = 'app_icon',
    bool enableRemoteNotifications = false,
    String? appId,
  }) async {
    final notifService = LocalNotificationService();
    await notifService.initialize(
      defaultChannelId: defaultNotificationChannelId,
      defaultChannelName: defaultNotificationChannelName,
      defaultChannelDescription: defaultNotificationChannelDesc,
      defaultAndroidIcon: defaultAndroidIcon,
    );

    RemoteNotificationService? remoteNotifService;
    if (enableRemoteNotifications) {
      remoteNotifService = FCMNotificationService();
      await remoteNotifService.initialize();
    }

    // Dispose existing Supabase instance if previously initialized to allow hot swapping backend endpoints
    try {
      await Supabase.instance.dispose();
    } catch (_) {}

    final isManaged = config.backendType == BackendType.managed;
    final url = (isManaged ? defaultSupabaseUrl : config.supabaseUrl) ?? '';
    final anonKey =
        (isManaged ? defaultSupabaseAnonKey : config.supabaseAnonKey) ?? '';

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      postgrestOptions: PostgrestClientOptions(schema: dbSchema),
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    final client = Supabase.instance.client;
    
    final authRepo = SupabaseAuthImpl(
      client: client,
      remoteNotificationService: remoteNotifService,
      appId: appId,
    );
    
    final dbRepo = SupabaseDatabaseImpl(client: client, schema: dbSchema);

    return [
      supabaseClientProvider.overrideWithValue(client),
      authRepositoryProvider.overrideWithValue(authRepo),
      databaseRepositoryProvider.overrideWithValue(dbRepo),
      notificationServiceProvider.overrideWithValue(notifService),
      if (remoteNotifService != null)
        remoteNotificationServiceProvider.overrideWithValue(remoteNotifService),
    ];
  }
}
