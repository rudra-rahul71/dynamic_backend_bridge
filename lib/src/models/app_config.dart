enum BackendType {
  managed,
  byoFirebase,
  supabase,
}

class AppConfig {
  final BackendType backendType;
  
  // BYO Firebase config
  final String? firebaseApiKey;
  final String? firebaseAppId;
  final String? firebaseMessagingSenderId;
  final String? firebaseProjectId;
  
  // Supabase config
  final String? supabaseUrl;
  final String? supabaseAnonKey;

  AppConfig({
    required this.backendType,
    this.firebaseApiKey,
    this.firebaseAppId,
    this.firebaseMessagingSenderId,
    this.firebaseProjectId,
    this.supabaseUrl,
    this.supabaseAnonKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'backendType': backendType.name,
      'firebaseApiKey': firebaseApiKey,
      'firebaseAppId': firebaseAppId,
      'firebaseMessagingSenderId': firebaseMessagingSenderId,
      'firebaseProjectId': firebaseProjectId,
      'supabaseUrl': supabaseUrl,
      'supabaseAnonKey': supabaseAnonKey,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      backendType: BackendType.values.firstWhere(
        (e) => e.name == json['backendType'],
        orElse: () => BackendType.managed,
      ),
      firebaseApiKey: json['firebaseApiKey'],
      firebaseAppId: json['firebaseAppId'],
      firebaseMessagingSenderId: json['firebaseMessagingSenderId'],
      firebaseProjectId: json['firebaseProjectId'],
      supabaseUrl: json['supabaseUrl'],
      supabaseAnonKey: json['supabaseAnonKey'],
    );
  }
}
