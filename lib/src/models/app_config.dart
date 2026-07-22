enum BackendType {
  managed,
  customSupabase,
}

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
    BackendType type = BackendType.managed;
    if (rawType == 'customSupabase' || rawType == 'supabase' || rawType == 'byoFirebase') {
      type = (rawType == 'managed') ? BackendType.managed : BackendType.customSupabase;
    }

    return AppConfig(
      backendType: type,
      supabaseUrl: json['supabaseUrl'],
      supabaseAnonKey: json['supabaseAnonKey'],
    );
  }
}
