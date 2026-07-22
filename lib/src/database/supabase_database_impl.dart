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

    return streamQuery
        .map((list) {
          var maps = list.map((map) => Map<String, dynamic>.from(map)).toList();

          // Apply any secondary filters client-side robustly
          if (filters != null && filters.length > 1) {
            final remainingFilters = filters.skip(1);
            for (final filter in remainingFilters) {
              maps = maps.where((map) {
                final val = map[filter.field];
                final targetVal = filter.value;

                if (filter.operator == FilterOperator.equal) {
                  if (val == null) return targetVal == null;
                  return val.toString() == targetVal.toString();
                }

                if (val == null || targetVal == null) return false;

                // Handle DateTimes
                if (val is String && targetVal is DateTime) {
                  final parsedVal = DateTime.tryParse(val);
                  if (parsedVal != null) {
                    if (filter.operator == FilterOperator.greaterThan) {
                      return parsedVal.isAfter(targetVal);
                    } else if (filter.operator == FilterOperator.lessThan) {
                      return parsedVal.isBefore(targetVal);
                    }
                  }
                }

                // Handle Numbers
                if (val is num && targetVal is num) {
                  if (filter.operator == FilterOperator.greaterThan) {
                    return val > targetVal;
                  } else if (filter.operator == FilterOperator.lessThan) {
                    return val < targetVal;
                  }
                }

                // Generic Comparables
                if (val is Comparable && targetVal is Comparable) {
                  final cmp = val.compareTo(targetVal);
                  if (filter.operator == FilterOperator.greaterThan) {
                    return cmp > 0;
                  } else if (filter.operator == FilterOperator.lessThan) {
                    return cmp < 0;
                  }
                }

                return false;
              }).toList();
            }
          }
          return maps;
        })
        .handleError((error, stackTrace) {
          // Log stream disconnection error and yield empty/error state cleanly
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
