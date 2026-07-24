# dynamic_backend_bridge

A Flutter package that provides a dynamic, decoupled interface for switching between Supabase backends (Managed Cloud, Custom Supabase Cloud, and Self-Hosted Docker instances) at runtime. It includes a built-in dark-themed onboarding wizard UI, a unified Auth layer, and a generic map-based Database layer with query filtering support.

## Features

- **Runtime Backend Switching:** Swap between a Managed Supabase Cloud Backend, a Custom `supabase.com` project, or a self-hosted Docker VPS instance dynamically without rebuilds.
- **Unified Authentication:** Perform sign-in, sign-up, sign-out, session restoration, and connection health checks via a single abstract interface (`AuthRepository`).
- **Generic Database Bridge:** Read, write, and stream records reactively using a generic, map-based repository interface (`DatabaseRepository`).
- **Type-Safe Collections (`TypedCollection<T>`):** Easily wrap the database repository to serialize and deserialize your custom domain models.
- **Onboarding/Hosting Wizard:** A premium, dark-themed UI configuration screen (`HostingWizard`) allowing users or admins to configure and validate backend endpoints.

## Backend Modes

`dynamic_backend_bridge` supports two runtime deployment modes:

1. **`BackendType.managed` (Our Managed Cloud)**:
   Connects to your organization's default managed Supabase instance. The app developer supplies `defaultSupabaseUrl` and `defaultSupabaseAnonKey` programmatically (or via `AppEnvironment` / `--dart-define`). End users do not need to configure anything.
2. **`BackendType.customSupabase` (Your Own Supabase Server)**:
   Allows end-users or administrators to enter their own Supabase Project URL & Anon Key via `HostingWizard`. Works seamlessly for both `supabase.com` Cloud projects and private self-hosted Docker VPS servers.

## Getting Started

Add the package to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  dynamic_backend_bridge: ^0.0.4
```

Run `flutter pub get` to install the dependencies.

## Usage

### 1. Initialize the Bridge

In your application's `main()` or bootstrapping sequence, check for any saved configuration and initialize the dynamic backend bridge:

```dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

final getIt = GetIt.instance;

// Centralize credentials in a single environment class or --dart-define
class AppEnvironment {
  static const String defaultSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co',
  );
  static const String defaultSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR...',
  );
}

// Single helper function to initialize backend
Future<void> initializeBackend(AppConfig config) async {
  await DynamicBackendBridge.initialize(
    config: config,
    getIt: getIt,
    defaultSupabaseUrl: AppEnvironment.defaultSupabaseUrl,
    defaultSupabaseAnonKey: AppEnvironment.defaultSupabaseAnonKey,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configService = ConfigService();
  final savedConfig = await configService.getSavedConfig();

  if (savedConfig != null) {
    await initializeBackend(savedConfig);
  }

  runApp(MyApp(
    configService: configService,
    initialConfig: savedConfig,
  ));
}
```

### 2. Integrate the Hosting Wizard Onboarding Screen

If no configuration exists on startup, present the `HostingWizard` widget to onboarding the user:

```dart
HostingWizard(
  configService: widget.configService,
  onValidate: (AppConfig config) async {
    // Validate configuration health checks (offline test / credentials sanity check)
    try {
      await initializeBackend(config);
      final auth = getIt<AuthRepository>();
      return await auth.validateConnection();
    } catch (e) {
      return e.toString();
    }
  },
  onComplete: (AppConfig config) {
    // Navigate or update state to load main application flow
  },
)
```

### 3. Using the Unified Auth Layer

Access authentication singletons dynamically from the locator:

```dart
final auth = getIt<AuthRepository>();

// Sign In
final user = await auth.signIn('user@example.com', 'password');

// Sign Out
await auth.signOut();
```

### 4. Using the Generic Database Layer with `TypedCollection`

Define your custom domain models client-side and map them using `TypedCollection<T>`:

```dart
class Task {
  final String id;
  final String title;
  final String userId;

  Task({required this.id, required this.title, required this.userId});

  Map<String, dynamic> toMap() => {
    'title': title,
    'userId': userId,
  };

  static Task fromMap(Map<String, dynamic> map, String id) => Task(
    id: id,
    title: map['title'] ?? '',
    userId: map['userId'] ?? '',
  );
}

// Instantiate collection wrapper
final taskCollection = TypedCollection<Task>(
  repo: getIt<DatabaseRepository>(),
  collectionName: 'tasks',
  toMap: (task) => task.toMap(),
  fromMap: (map, id) => Task.fromMap(map, id),
);

// Save items
await taskCollection.save(Task(id: '', title: 'Buy milk', userId: 'user123'), 'document-id');

// Watch changes reactively with query filters
final stream = taskCollection.watch(
  filters: [QueryFilter.eq('userId', 'user123')],
);
```

## Additional Information

For issues, contributions, or configuration details, please refer to the package repository.
