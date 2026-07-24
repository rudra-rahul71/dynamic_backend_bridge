abstract class UserEntity {
  String get uid;
  String get email;
}

class SimpleUserEntity implements UserEntity {
  @override
  final String uid;
  @override
  final String email;

  const SimpleUserEntity({required this.uid, required this.email});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleUserEntity &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email;

  @override
  int get hashCode => uid.hashCode ^ email.hashCode;

  @override
  String toString() => 'SimpleUserEntity(uid: $uid, email: $email)';
}

abstract class AuthRepository {
  Future<UserEntity?> signIn(String email, String password);
  Future<UserEntity?> signUp(String email, String password);
  Future<void> signOut();
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
  Future<String?> validateConnection();
}
