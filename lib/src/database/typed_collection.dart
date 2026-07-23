import 'database_repository.dart';
import 'query_filter.dart';

class TypedCollection<T> {
  final DatabaseRepository _repo;
  final String collectionName;
  final Map<String, dynamic> Function(T) toMap;
  final T Function(Map<String, dynamic> map, String id) fromMap;

  TypedCollection({
    required DatabaseRepository repo,
    required this.collectionName,
    required this.toMap,
    required this.fromMap,
  }) : _repo = repo;

  Future<void> save(T item, String id) {
    return _repo.saveMap(
      collection: collectionName,
      id: id,
      data: toMap(item),
    );
  }

  Future<List<T>> fetch({List<QueryFilter>? filters}) async {
    final list = await _repo.fetchMap(collection: collectionName, filters: filters);
    return list.map((map) => fromMap(map, map['id']?.toString() ?? '')).toList();
  }

  Stream<List<T>> watch({List<QueryFilter>? filters}) {
    return _repo.watchMap(collection: collectionName, filters: filters)
        .map((list) => list.map((map) => fromMap(map, map['id']?.toString() ?? '')).toList());
  }

  Future<void> delete(String id) {
    return _repo.deleteMap(
      collection: collectionName,
      id: id,
    );
  }
}
