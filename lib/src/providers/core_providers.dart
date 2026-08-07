import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_repository.dart';
import '../database/database_repository.dart';
import '../services/notification_service.dart';
import '../services/remote_notification_service.dart';

/// Provider for the Supabase Client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for AuthRepository
/// This provider throws an UnimplementedError by default and must be overridden 
/// or properly initialized by the host app via ProviderScope.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('authRepositoryProvider must be overridden');
});

/// Provider for DatabaseRepository
final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  throw UnimplementedError('databaseRepositoryProvider must be overridden');
});

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('notificationServiceProvider must be overridden');
});

/// Provider for RemoteNotificationService
final remoteNotificationServiceProvider = Provider<RemoteNotificationService?>((ref) {
  return null;
});

/// Provider for the current UserEntity (Authentication state)
final currentUserProvider = StreamProvider((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});
