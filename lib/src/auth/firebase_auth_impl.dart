import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'auth_repository.dart';

class FirebaseAuthImpl implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;

  fb.FirebaseAuth get firebaseAuth => _firebaseAuth;

  FirebaseAuthImpl({fb.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  @override
  UserEntity? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null
        ? SimpleUserEntity(uid: user.uid, email: user.email ?? '')
        : null;
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      return user != null
          ? SimpleUserEntity(uid: user.uid, email: user.email ?? '')
          : null;
    });
  }

  @override
  Future<UserEntity?> signIn(String email, String password) async {
    final credentials = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credentials.user;
    return user != null
        ? SimpleUserEntity(uid: user.uid, email: user.email ?? '')
        : null;
  }

  @override
  Future<UserEntity?> signUp(String email, String password) async {
    final credentials = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credentials.user;
    return user != null
        ? SimpleUserEntity(uid: user.uid, email: user.email ?? '')
        : null;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<String?> validateConnection() async {
    try {
      await _firebaseAuth
          .sendPasswordResetEmail(email: 'validation_test@example.com')
          .timeout(const Duration(seconds: 4));
      return null;
    } catch (e) {
      return 'Unable to connect to Firebase Project.';
    }
  }
}
