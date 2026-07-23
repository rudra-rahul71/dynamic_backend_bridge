import 'query_filter.dart';

abstract class DatabaseRepository {
  Future<void> saveMap({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  });

  Future<List<Map<String, dynamic>>> fetchMap({
    required String collection,
    List<QueryFilter>? filters,
  });

  Stream<List<Map<String, dynamic>>> watchMap({
    required String collection,
    List<QueryFilter>? filters,
  });

  Future<void> deleteMap({
    required String collection,
    required String id,
  });
}
