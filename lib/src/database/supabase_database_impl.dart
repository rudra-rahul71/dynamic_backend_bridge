import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_repository.dart';
import 'query_filter.dart';

class SupabaseDatabaseImpl implements DatabaseRepository {
  final SupabaseClient client;

  SupabaseDatabaseImpl({required this.client});

  @override
  Future<void> saveMap({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final payload = Map<String, dynamic>.from(data);
    if (id.isNotEmpty && !payload.containsKey('id')) {
      payload['id'] = id;
    }
    await client.from(collection).upsert(payload);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMap({
    required String collection,
    List<QueryFilter>? filters,
  }) {
    final streamBuilder = client.from(collection).stream(primaryKey: ['id']);
    Stream<List<Map<String, dynamic>>> streamQuery;

    if (filters != null && filters.isNotEmpty) {
      final firstFilter = filters.first;
      if (firstFilter.operator == FilterOperator.equal) {
        streamQuery = streamBuilder.eq(firstFilter.field, firstFilter.value);
      } else if (firstFilter.operator == FilterOperator.greaterThan) {
        streamQuery = streamBuilder.gt(firstFilter.field, firstFilter.value);
      } else if (firstFilter.operator == FilterOperator.lessThan) {
        streamQuery = streamBuilder.lt(firstFilter.field, firstFilter.value);
      } else {
        streamQuery = streamBuilder;
      }
    } else {
      streamQuery = streamBuilder;
    }

    return streamQuery.map((list) {
      var maps = list.map((map) => Map<String, dynamic>.from(map)).toList();

      // Apply any secondary filters client-side (Supabase streams only support a single server-side filter)
      if (filters != null && filters.length > 1) {
        final remainingFilters = filters.skip(1);
        for (final filter in remainingFilters) {
          if (filter.operator == FilterOperator.equal) {
            maps = maps.where((map) {
              final val = map[filter.field];
              if (val == null) return filter.value == null;
              return val.toString() == filter.value.toString();
            }).toList();
          } else if (filter.operator == FilterOperator.greaterThan) {
            maps = maps.where((map) {
              final val = map[filter.field];
              if (val is Comparable && filter.value is Comparable) {
                return val.compareTo(filter.value) > 0;
              }
              return false;
            }).toList();
          } else if (filter.operator == FilterOperator.lessThan) {
            maps = maps.where((map) {
              final val = map[filter.field];
              if (val is Comparable && filter.value is Comparable) {
                return val.compareTo(filter.value) < 0;
              }
              return false;
            }).toList();
          }
        }
      }
      return maps;
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
