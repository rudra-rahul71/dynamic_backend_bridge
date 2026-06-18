abstract class UserEntity {
  String get uid;
  String get email;
}

class SimpleUserEntity implements UserEntity {
  @override
  final String uid;
  @override
  final String email;

  SimpleUserEntity({required this.uid, required this.email});
}

abstract class AuthRepository {
  Future<UserEntity?> signIn(String email, String password);
  Future<UserEntity?> signUp(String email, String password);
  Future<void> signOut();
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
  Future<String?> validateConnection();
}
