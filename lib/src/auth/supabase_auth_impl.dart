import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

class SupabaseAuthImpl implements AuthRepository {
  final SupabaseClient client;

  SupabaseAuthImpl({required this.client});

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
