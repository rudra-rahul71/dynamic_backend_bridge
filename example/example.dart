import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configService = ConfigService();
  final config =
      await configService.getSavedConfig() ??
      AppConfig(backendType: BackendType.managed);

  // Initialize the Dynamic Backend Bridge with optional default managed Supabase credentials
  await DynamicBackendBridge.initialize(
    config: config,
    getIt: getIt,
    defaultSupabaseUrl: 'https://your-project.supabase.co',
    defaultSupabaseAnonKey: 'your-anon-key',
  );

  runApp(MyApp(configService: configService));
}

class MyApp extends StatelessWidget {
  final ConfigService configService;
  const MyApp({super.key, required this.configService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Backend Bridge Example',
      theme: ThemeData.dark(),
      home: HomeScreen(configService: configService),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final ConfigService configService;
  const HomeScreen({super.key, required this.configService});

  @override
  Widget build(BuildContext context) {
    final db = getIt<DatabaseRepository>();
    final auth = getIt<AuthRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Bridge Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to built-in Hosting Wizard UI
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HostingWizard(
                    configService: configService,
                    onValidate: (newConfig) async {
                      // Return null on successful validation, or an error string
                      return null;
                    },
                    onComplete: (newConfig) async {
                      await DynamicBackendBridge.initialize(
                        config: newConfig,
                        getIt: getIt,
                        defaultSupabaseUrl: 'https://your-project.supabase.co',
                        defaultSupabaseAnonKey: 'your-anon-key',
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'User Logged In: ${auth.currentUser != null}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final tasks = await db.fetchMap(collection: 'tasks');
                debugPrint('Fetched ${tasks.length} tasks.');
              },
              child: const Text('Fetch Data'),
            ),
          ],
        ),
      ),
    );
  }
}
