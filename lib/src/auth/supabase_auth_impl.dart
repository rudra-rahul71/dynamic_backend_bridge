import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';
import '../services/remote_notification_service.dart';

class SupabaseAuthImpl implements AuthRepository {
  final SupabaseClient client;
  final RemoteNotificationService? remoteNotificationService;
  final String? appId;
  StreamSubscription? _authStateSubscription;
  StreamSubscription? _tokenRefreshSubscription;

  SupabaseAuthImpl({
    required this.client,
    this.remoteNotificationService,
    this.appId,
  }) {
    _setupPushNotificationListeners();
  }

  void _setupPushNotificationListeners() {
    final currentAppId = appId;
    final notifService = remoteNotificationService;
    if (notifService == null || currentAppId == null || kIsWeb) return;

    _authStateSubscription = client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event = data.event;

      if (event == AuthChangeEvent.signedIn && session != null) {
        await _registerPushToken(session.user.id);
      }
    });

    _tokenRefreshSubscription = notifService.onTokenRefresh.listen((
      newToken,
    ) async {
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        await _registerPushToken(userId, newToken: newToken);
      }
    });
  }

  Future<void> _registerPushToken(String userId, {String? newToken}) async {
    try {
      final token = newToken ?? await remoteNotificationService!.getToken();
      if (token != null) {
        final platform = Platform.isIOS ? 'ios' : 'android';
        await client.schema('users').from('device_tokens').upsert({
          'user_id': userId,
          'app_id': appId!,
          'token': token,
          'platform': platform,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id, app_id, token');
      }
    } catch (e) {
      debugPrint('Failed to register push token: $e');
    }
  }

  Future<void> _unregisterPushToken() async {
    final currentAppId = appId;
    final notifService = remoteNotificationService;
    if (notifService == null || currentAppId == null || kIsWeb) return;

    try {
      final token = await notifService.getToken();
      if (token != null) {
        await client.schema('users').from('device_tokens').delete().match({
          'app_id': currentAppId,
          'token': token,
        });
      }
    } catch (e) {
      debugPrint('Failed to unregister push token: $e');
    }
  }

  void dispose() {
    _authStateSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
  }

  UserEntity? _mapUser(User? user) {
    if (user == null) return null;
    return SimpleUserEntity(uid: user.id, email: user.email ?? '');
  }

  @override
  UserEntity? get currentUser => _mapUser(client.auth.currentUser);

  @override
  Stream<UserEntity?> get authStateChanges async* {
    yield currentUser;
    await for (final data in client.auth.onAuthStateChange) {
      yield _mapUser(data.session?.user ?? client.auth.currentUser);
    }
  }

  @override
  Future<UserEntity?> signIn(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _mapUser(response.user);
  }

  @override
  Future<UserEntity?> signUp(String email, String password) async {
    final response = await client.auth.signUp(email: email, password: password);
    return _mapUser(response.user);
  }

  @override
  Future<void> signOut() async {
    await _unregisterPushToken();
    await client.auth.signOut();
  }

  @override
  Future<String?> validateConnection() async {
    try {
      await client.storage.listBuckets().timeout(const Duration(seconds: 4));
      return null;
    } on TimeoutException {
      return 'Connection timed out. Server unreachable or offline.';
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Failed host lookup')) {
        return 'Network error: Server host unreachable.';
      }
      return 'Supabase connection failed: $msg';
    }
  }
}
