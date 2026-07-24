import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('DynamicBackendBridge re-initialization test', () async {
    final getIt = GetIt.instance;

    final config1 = AppConfig(backendType: BackendType.managed);
    await DynamicBackendBridge.initialize(
      config: config1,
      getIt: getIt,
      defaultSupabaseUrl: 'https://managed.supabase.co',
      defaultSupabaseAnonKey:
          'managedKey1234567890123456789012345678901234567890',
    );

    final url1 = Supabase.instance.client.rest.url;
    expect(url1, contains('managed.supabase.co'));

    final config2 = AppConfig(
      backendType: BackendType.customSupabase,
      supabaseUrl: 'https://custom.supabase.co',
      supabaseAnonKey: 'customKey1234567890123456789012345678901234567890',
    );

    await DynamicBackendBridge.initialize(
      config: config2,
      getIt: getIt,
      defaultSupabaseUrl: 'https://managed.supabase.co',
      defaultSupabaseAnonKey:
          'managedKey1234567890123456789012345678901234567890',
    );

    final url2 = Supabase.instance.client.rest.url;
    expect(url2, contains('custom.supabase.co'));
  });
}
