import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_repository.dart';
import 'query_filter.dart';

Map<String, dynamic> _serializeDateTimes(Map<String, dynamic> map) {
  final result = <String, dynamic>{};
  map.forEach((key, value) {
    if (value is DateTime) {
      result[key] = value.toUtc().toIso8601String();
    } else if (value is Map) {
      result[key] = _serializeDateTimes(Map<String, dynamic>.from(value));
    } else if (value is List) {
      result[key] = value.map((item) {
        if (item is DateTime) return item.toUtc().toIso8601String();
        if (item is Map) {
          return _serializeDateTimes(Map<String, dynamic>.from(item));
        }
        return item;
      }).toList();
    } else {
      result[key] = value;
    }
  });
  return result;
}

class SupabaseDatabaseImpl implements DatabaseRepository {
  final SupabaseClient client;

  SupabaseDatabaseImpl({required this.client});

  @override
  Future<void> saveMap({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final payload = _serializeDateTimes(data);
    if (id.isNotEmpty && !payload.containsKey('id')) {
      payload['id'] = id;
    }
    await client.from(collection).upsert(payload);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMap({
    required String collection,
    List<QueryFilter>? filters,
  }) async {
    dynamic query = client.from(collection).select();
    if (filters != null && filters.isNotEmpty) {
      for (final filter in filters) {
        query = switch (filter.operator) {
          FilterOperator.equal => query.eq(filter.field, filter.value),
          FilterOperator.notEqual => query.neq(filter.field, filter.value),
          FilterOperator.greaterThan => query.gt(filter.field, filter.value),
          FilterOperator.greaterThanOrEqual => query.gte(
            filter.field,
            filter.value,
          ),
          FilterOperator.lessThan => query.lt(filter.field, filter.value),
          FilterOperator.lessThanOrEqual => query.lte(
            filter.field,
            filter.value,
          ),
          FilterOperator.inFilter => query.inFilter(
            filter.field,
            filter.value as List,
          ),
        };
      }
    }
    final List response = await query;
    return response
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMap({
    required String collection,
    List<QueryFilter>? filters,
    List<String> primaryKey = const ['id'],
  }) {
    dynamic filterBuilder = client
        .from(collection)
        .stream(primaryKey: primaryKey);

    if (filters != null && filters.isNotEmpty) {
      for (final filter in filters) {
        filterBuilder = switch (filter.operator) {
          FilterOperator.equal => filterBuilder.eq(filter.field, filter.value),
          FilterOperator.notEqual => filterBuilder.neq(
            filter.field,
            filter.value,
          ),
          FilterOperator.greaterThan => filterBuilder.gt(
            filter.field,
            filter.value,
          ),
          FilterOperator.greaterThanOrEqual => filterBuilder.gte(
            filter.field,
            filter.value,
          ),
          FilterOperator.lessThan => filterBuilder.lt(
            filter.field,
            filter.value,
          ),
          FilterOperator.lessThanOrEqual => filterBuilder.lte(
            filter.field,
            filter.value,
          ),
          FilterOperator.inFilter => filterBuilder.inFilter(
            filter.field,
            filter.value as List,
          ),
        };
      }
    }

    return (filterBuilder as Stream).map(
      (list) => (list as List)
          .map((map) => Map<String, dynamic>.from(map as Map))
          .toList(),
    );
  }

  @override
  Future<void> deleteMap({
    required String collection,
    required String id,
    String primaryKey = 'id',
  }) async {
    final parsedId = int.tryParse(id) ?? id;
    await client.from(collection).delete().eq(primaryKey, parsedId);
  }
}
