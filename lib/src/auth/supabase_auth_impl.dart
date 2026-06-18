import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

class SupabaseAuthImpl implements AuthRepository {
  final SupabaseClient client;

  SupabaseAuthImpl({required this.client});

  @override
  UserEntity? get currentUser {
    final user = client.auth.currentUser;
    return user != null
        ? SimpleUserEntity(uid: user.id, email: user.email ?? '')
        : null;
  }

  @override
  Stream<UserEntity?> get authStateChanges async* {
    yield currentUser;
    await for (final data in client.auth.onAuthStateChange) {
      final user = data.session?.user ?? client.auth.currentUser;
      yield user != null
          ? SimpleUserEntity(uid: user.id, email: user.email ?? '')
          : null;
    }
  }

  @override
  Future<UserEntity?> signIn(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    return user != null
        ? SimpleUserEntity(uid: user.id, email: user.email ?? '')
        : null;
  }

  @override
  Future<UserEntity?> signUp(String email, String password) async {
    final response = await client.auth.signUp(email: email, password: password);
    final user = response.user;
    return user != null
        ? SimpleUserEntity(uid: user.id, email: user.email ?? '')
        : null;
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
    } catch (e) {
      return 'Supabase connection failed.';
    }
  }
}
