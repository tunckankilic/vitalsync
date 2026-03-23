/// VitalSync — Firestore implementation of CloudSyncClient.
///
/// Wraps Cloud Firestore operations behind the CloudSyncClient interface.
/// This will be replaced by RestSyncClient after AWS migration.
library;

import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloud_sync_client.dart';

/// Firestore-based implementation of [CloudSyncClient].
///
/// Data structure:
///   users/{userId}/{collection}/{recordId}
class FirestoreSyncClient implements CloudSyncClient {
  FirestoreSyncClient({required FirebaseFirestore firestore})
    : _firestore = firestore;
  final FirebaseFirestore _firestore;

  @override
  Future<DateTime?> pushRecord({
    required String userId,
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(recordId);

    if (merge) {
      await docRef.set(data, SetOptions(merge: true));
    } else {
      await docRef.set(data);
    }

    // Firestore doesn't return a timestamp on set, return null
    return null;
  }

  @override
  Future<void> deleteRecord({
    required String userId,
    required String collection,
    required String recordId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(recordId)
        .delete();
  }

  @override
  Future<List<CloudSyncRecord>> pullRecords({
    required String userId,
    required String collection,
    DateTime? since,
  }) async {
    final collectionRef = _firestore
        .collection('users')
        .doc(userId)
        .collection(collection);

    Query<Map<String, dynamic>> query;
    if (since != null) {
      final sinceTimestamp = Timestamp.fromDate(since);
      query = collectionRef
          .where('lastModifiedAt', isGreaterThan: sinceTimestamp)
          .orderBy('lastModifiedAt');
    } else {
      query = collectionRef;
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = _convertFromFirestoreFormat(doc.data());
      final timestamp = doc.data()['lastModifiedAt'] as Timestamp?;
      final modifiedAt = timestamp?.toDate() ?? DateTime.now();

      return CloudSyncRecord(
        id: doc.id,
        data: data,
        lastModifiedAt: modifiedAt,
      );
    }).toList();
  }

  @override
  Future<DateTime?> getRemoteModifiedAt({
    required String userId,
    required String collection,
    required String recordId,
  }) async {
    final docSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(recordId)
        .get();

    if (!docSnapshot.exists) return null;

    final remoteModifiedAt =
        docSnapshot.data()?['lastModifiedAt'] as Timestamp?;
    return remoteModifiedAt?.toDate();
  }

  @override
  Future<void> deleteAllUserData({
    required String userId,
    required List<String> collections,
  }) async {
    final userDocRef = _firestore.collection('users').doc(userId);

    for (final collection in collections) {
      try {
        final snapshot = await userDocRef.collection(collection).get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
        log('Deleted Firestore collection: $collection');
      } catch (e) {
        log('Error deleting Firestore collection $collection: $e');
      }
    }

    // Also delete insights (optional collection)
    try {
      final insightsSnapshot =
          await userDocRef.collection('insights').get();
      for (final doc in insightsSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      log('Error deleting insights: $e');
    }

    // Delete the user document itself
    await userDocRef.delete();
    log('Firestore user data deleted for $userId');
  }

  @override
  Future<Map<String, dynamic>> exportAllUserData({
    required String userId,
    required List<String> collections,
  }) async {
    final exportData = <String, dynamic>{};

    for (final collection in collections) {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .get();

      exportData[collection] = snapshot.docs.map((doc) {
        return _convertFromFirestoreFormat(doc.data());
      }).toList();
    }

    return exportData;
  }

  /// Converts a Firestore document map to local database format.
  /// - Firestore [Timestamp] → ISO 8601 String
  /// - Handles nested maps recursively
  Map<String, dynamic> _convertFromFirestoreFormat(
    Map<String, dynamic> data,
  ) {
    final result = <String, dynamic>{};

    for (final entry in data.entries) {
      final value = entry.value;

      if (value == null) {
        result[entry.key] = null;
      } else if (value is Timestamp) {
        result[entry.key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[entry.key] = _convertFromFirestoreFormat(value);
      } else if (value is List) {
        result[entry.key] = value.map((item) {
          if (item is Timestamp) return item.toDate().toIso8601String();
          if (item is Map<String, dynamic>) {
            return _convertFromFirestoreFormat(item);
          }
          return item;
        }).toList();
      } else {
        result[entry.key] = value;
      }
    }

    return result;
  }
}
