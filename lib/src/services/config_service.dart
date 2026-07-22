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
    try {
      // 1. Try reading from FlutterSecureStorage
      final secureVal = await _secureStorage.read(key: _configKey);
      if (secureVal != null && secureVal.isNotEmpty) {
        final jsonMap = json.decode(secureVal) as Map<String, dynamic>;
        return AppConfig.fromJson(jsonMap);
      }

      // 2. Migration fallback: read legacy SharedPreferences if present
      final prefs = await SharedPreferences.getInstance();
      final legacyStr = prefs.getString(_configKey);
      if (legacyStr != null && legacyStr.isNotEmpty) {
        try {
          final jsonMap = json.decode(legacyStr) as Map<String, dynamic>;
          final config = AppConfig.fromJson(jsonMap);
          // Migrate to secure storage & delete legacy plaintext string
          await saveConfig(config);
          await prefs.remove(_configKey);
          return config;
        } catch (_) {}
      }
    } catch (_) {
      // Fallback for platform environments where FlutterSecureStorage might throw
      try {
        final prefs = await SharedPreferences.getInstance();
        final legacyStr = prefs.getString(_configKey);
        if (legacyStr != null && legacyStr.isNotEmpty) {
          final jsonMap = json.decode(legacyStr) as Map<String, dynamic>;
          return AppConfig.fromJson(jsonMap);
        }
      } catch (_) {}
    }
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
  }
}
