import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class ConfigService {
  static const String _configKey = 'app_backend_config';
  final FlutterSecureStorage _secureStorage;

  ConfigService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<AppConfig?> getSavedConfig() async {
    // 1. Try reading from FlutterSecureStorage
    try {
      final secureVal = await _secureStorage.read(key: _configKey);
      if (secureVal != null && secureVal.isNotEmpty) {
        final jsonMap = json.decode(secureVal) as Map<String, dynamic>;
        return AppConfig.fromJson(jsonMap);
      }
    } catch (_) {}

    // 2. Fallback to SharedPreferences if secure storage is empty or throws
    try {
      final prefs = await SharedPreferences.getInstance();
      final strVal = prefs.getString(_configKey);
      if (strVal != null && strVal.isNotEmpty) {
        final jsonMap = json.decode(strVal) as Map<String, dynamic>;
        return AppConfig.fromJson(jsonMap);
      }
    } catch (_) {}

    return null;
  }

  Future<void> saveConfig(AppConfig config) async {
    final jsonStr = json.encode(config.toJson());
    try {
      await _secureStorage.write(key: _configKey, value: jsonStr);
    } catch (_) {
      // Fallback if secure storage is unavailable on specific platform/test runner
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_configKey, jsonStr);
    }
  }

  Future<void> clearConfig() async {
    try {
      await _secureStorage.delete(key: _configKey);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_configKey);
    } catch (_) {}
  }
}
