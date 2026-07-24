import 'package:flutter_test/flutter_test.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

class FakeDatabaseRepository implements DatabaseRepository {
  final Map<String, List<Map<String, dynamic>>> storage = {};

  @override
  Future<void> saveMap({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    storage.putIfAbsent(collection, () => []);
    storage[collection]!.add({...data, 'id': id});
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMap({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    final list = storage[collection] ?? [];
    if (filters == null || filters.isEmpty) return list;
    return list.where((item) {
      return filters.every((filter) {
        final val = item[filter.field];
        return switch (filter.operator) {
          FilterOperator.equal => val == filter.value,
          FilterOperator.notEqual => val != filter.value,
          FilterOperator.greaterThan => val > filter.value,
          FilterOperator.greaterThanOrEqual => val >= filter.value,
          FilterOperator.lessThan => val < filter.value,
          FilterOperator.lessThanOrEqual => val <= filter.value,
          FilterOperator.inFilter => (filter.value as List).contains(val),
        };
      });
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMap({
    required String collection,
    List<QueryFilter>? filters,
    List<String> primaryKey = const ['id'],
  }) {
    return Stream.value(storage[collection] ?? []);
  }

  @override
  Future<void> deleteMap({
    required String collection,
    required String id,
    String primaryKey = 'id',
  }) async {
    storage[collection]?.removeWhere((item) => item[primaryKey]?.toString() == id);
  }
}

class SampleModel {
  final String uuid;
  final String name;
  final int age;

  SampleModel({required this.uuid, required this.name, required this.age});
}

void main() {
  group('QueryFilter & TypedCollection Tests', () {
    late FakeDatabaseRepository repo;
    late TypedCollection<SampleModel> collection;

    setUp(() {
      repo = FakeDatabaseRepository();
      collection = TypedCollection<SampleModel>(
        repo: repo,
        collectionName: 'users',
        primaryKeyField: 'uuid',
        toMap: (item) => {'uuid': item.uuid, 'name': item.name, 'age': item.age},
        fromMap: (map, id) => SampleModel(
          uuid: id,
          name: map['name'] as String,
          age: map['age'] as int,
        ),
      );
    });

    test('TypedCollection uses custom primaryKeyField (uuid)', () async {
      final user = SampleModel(uuid: 'usr-123', name: 'Alice', age: 30);
      await collection.save(user, user.uuid);

      final results = await collection.fetch();
      expect(results.length, equals(1));
      expect(results.first.uuid, equals('usr-123'));
      expect(results.first.name, equals('Alice'));
    });

    test('QueryFilter supports all operators', () async {
      await collection.save(SampleModel(uuid: '1', name: 'Alice', age: 20), '1');
      await collection.save(SampleModel(uuid: '2', name: 'Bob', age: 30), '2');
      await collection.save(SampleModel(uuid: '3', name: 'Charlie', age: 40), '3');

      final gteResults = await collection.fetch(filters: [QueryFilter.gte('age', 30)]);
      expect(gteResults.length, equals(2));

      final lteResults = await collection.fetch(filters: [QueryFilter.lte('age', 20)]);
      expect(lteResults.length, equals(1));

      final neqResults = await collection.fetch(filters: [QueryFilter.neq('name', 'Bob')]);
      expect(neqResults.length, equals(2));

      final inResults = await collection.fetch(filters: [
        QueryFilter.inFilter('name', ['Alice', 'Charlie'])
      ]);
      expect(inResults.length, equals(2));
    });
  });
}
