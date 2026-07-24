import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

void main() {
  group('SimpleUserEntity Tests', () {
    test('instantiates with uid and email', () {
      const user = SimpleUserEntity(uid: 'user-1', email: 'test@example.com');
      expect(user.uid, equals('user-1'));
      expect(user.email, equals('test@example.com'));
      expect(user, isA<UserEntity>());
    });

    test('supports equality and hashCode', () {
      const user1 = SimpleUserEntity(uid: 'user-1', email: 'test@example.com');
      const user2 = SimpleUserEntity(uid: 'user-1', email: 'test@example.com');
      const user3 = SimpleUserEntity(uid: 'user-2', email: 'test@example.com');

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
      expect(user1, isNot(equals(user3)));
    });

    test('toString returns formatted string representation', () {
      const user = SimpleUserEntity(uid: 'user-1', email: 'test@example.com');
      expect(
        user.toString(),
        equals('SimpleUserEntity(uid: user-1, email: test@example.com)'),
      );
    });
  });
}
