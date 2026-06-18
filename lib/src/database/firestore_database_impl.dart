import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_repository.dart';
import 'query_filter.dart';

class FirestoreDatabaseImpl implements DatabaseRepository {
  final FirebaseFirestore _firestore;

  FirestoreDatabaseImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveMap({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    if (id.isEmpty) {
      await _firestore.collection(collection).add(data);
    } else {
      await _firestore.collection(collection).doc(id).set(data);
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMap({
    required String collection,
    List<QueryFilter>? filters,
  }) {
    Query query = _firestore.collection(collection);

    if (filters != null) {
      for (final filter in filters) {
        if (filter.operator == FilterOperator.equal) {
          query = query.where(filter.field, isEqualTo: filter.value);
        } else if (filter.operator == FilterOperator.greaterThan) {
          query = query.where(filter.field, isGreaterThan: filter.value);
        } else if (filter.operator == FilterOperator.lessThan) {
          query = query.where(filter.field, isLessThan: filter.value);
        }
      }
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  @override
  Future<void> deleteMap({
    required String collection,
    required String id,
  }) async {
    await _firestore.collection(collection).doc(id).delete();
  }
}
