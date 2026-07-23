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
        if (item is Map) return _serializeDateTimes(Map<String, dynamic>.from(item));
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
        if (filter.operator == FilterOperator.equal) {
          query = query.eq(filter.field, filter.value);
        } else if (filter.operator == FilterOperator.greaterThan) {
          query = query.gt(filter.field, filter.value);
        } else if (filter.operator == FilterOperator.lessThan) {
          query = query.lt(filter.field, filter.value);
        }
      }
    }
    final List response = await query;
    return response.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMap({
    required String collection,
    List<QueryFilter>? filters,
  }) {
    dynamic filterBuilder = client.from(collection).stream(primaryKey: ['id']);

    if (filters != null && filters.isNotEmpty) {
      for (final filter in filters) {
        if (filter.operator == FilterOperator.equal) {
          filterBuilder = filterBuilder.eq(filter.field, filter.value);
        } else if (filter.operator == FilterOperator.greaterThan) {
          filterBuilder = filterBuilder.gt(filter.field, filter.value);
        } else if (filter.operator == FilterOperator.lessThan) {
          filterBuilder = filterBuilder.lt(filter.field, filter.value);
        }
      }
    }

    final Stream<List<Map<String, dynamic>>> streamQuery = (filterBuilder as Stream)
        .map((list) => (list as List).map((map) => Map<String, dynamic>.from(map as Map)).toList());

    return streamQuery.handleError((error, stackTrace) {
      return <Map<String, dynamic>>[];
    });
  }

  @override
  Future<void> deleteMap({
    required String collection,
    required String id,
  }) async {
    final parsedId = int.tryParse(id) ?? id;
    await client.from(collection).delete().eq('id', parsedId);
  }
}
