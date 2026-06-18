import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class ConfigService {
  static const String _configKey = 'app_backend_config';
  
  Future<AppConfig?> getSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_configKey);
    if (jsonStr == null) return null;
    try {
      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
      return AppConfig.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveConfig(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(config.toJson());
    await prefs.setString(_configKey, jsonStr);
  }

  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
  }
}
