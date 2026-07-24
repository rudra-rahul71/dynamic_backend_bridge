import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('ConfigService', () {
    test('save, retrieve, and clear config', () async {
      final service = ConfigService();
      final config = AppConfig(
        backendType: BackendType.customSupabase,
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'key1234567890123456789012345678901234567890',
      );

      await service.saveConfig(config);
      final saved = await service.getSavedConfig();
      expect(saved, isNotNull);
      expect(saved?.supabaseUrl, equals('https://test.supabase.co'));

      await service.clearConfig();
      final cleared = await service.getSavedConfig();
      expect(cleared, isNull);
    });
  });
}
