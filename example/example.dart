import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';
import 'package:dynamic_backend_bridge/src/providers/core_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configService = ConfigService();
  final config =
      await configService.getSavedConfig() ??
      AppConfig(backendType: BackendType.managed);

  // Initialize the Dynamic Backend Bridge with optional default managed Supabase credentials
  final overrides = await DynamicBackendBridge.initialize(
    config: config,
    defaultSupabaseUrl: 'https://your-project.supabase.co',
    defaultSupabaseAnonKey: 'your-anon-key',
  );

  runApp(
    ProviderScope(
      overrides: overrides,
      child: MyApp(configService: configService),
    ),
  );
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

class HomeScreen extends ConsumerWidget {
  final ConfigService configService;
  const HomeScreen({super.key, required this.configService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseRepositoryProvider);
    final auth = ref.read(authRepositoryProvider);

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
                      final newOverrides = await DynamicBackendBridge.initialize(
                        config: newConfig,
                        defaultSupabaseUrl: 'https://your-project.supabase.co',
                        defaultSupabaseAnonKey: 'your-anon-key',
                      );
                      // In a real app, you would need to rebuild the ProviderScope with new overrides,
                      // or use a mutable provider to swap the clients out.
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
