enum BackendType { managed, customSupabase }

class AppConfig {
  final BackendType backendType;

  // Supabase config (for custom Cloud or Self-Hosted Docker instances)
  final String? supabaseUrl;
  final String? supabaseAnonKey;

  AppConfig({
    required this.backendType,
    this.supabaseUrl,
    this.supabaseAnonKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'backendType': backendType.name,
      'supabaseUrl': supabaseUrl,
      'supabaseAnonKey': supabaseAnonKey,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final rawType = json['backendType'];
    final type = (rawType == 'customSupabase')
        ? BackendType.customSupabase
        : BackendType.managed;

    return AppConfig(
      backendType: type,
      supabaseUrl: json['supabaseUrl'],
      supabaseAnonKey: json['supabaseAnonKey'],
    );
  }
}
