/// VitalSync — Shared DAOs (User Profile, GDPR, Sync Queue).
library;

import 'package:drift/drift.dart';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/data/local/database.dart';
import '../../tables/shared/gdpr_consent_log_table.dart';
import '../../tables/shared/sync_queue_table.dart';
import '../../tables/shared/user_profile_table.dart';

part 'user_profile_dao.g.dart';

/// DAO for user profile operations.
@DriftAccessor(tables: [UserProfiles])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  /// Get the current user profile (should be only one).
  Future<UserProfileData?> getCurrentUser() {
    return (select(userProfiles)..limit(1)).getSingleOrNull();
  }

  /// Get user by Firebase UID.
  Future<UserProfileData?> getUserByFirebaseUid(String firebaseUid) {
    return (select(
      userProfiles,
    )..where((tbl) => tbl.firebaseUid.equals(firebaseUid))).getSingleOrNull();
  }

  /// Insert a new user profile.
  Future<int> insertUser(UserProfilesCompanion user) {
    return into(userProfiles).insert(user);
  }

  /// Update an existing user profile.
  Future<bool> updateUser(UserProfileData user) {
    return update(userProfiles).replace(user);
  }

  /// Delete a user profile.
  Future<int> deleteUser(int id) {
    return (delete(userProfiles)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Watch the current user profile for realtime updates.
  Stream<UserProfileData?> watchCurrentUser() {
    return (select(userProfiles)..limit(1)).watchSingleOrNull();
  }
}

/// DAO for GDPR consent log operations.
@DriftAccessor(tables: [GdprConsentLogs])
class GdprDao extends DatabaseAccessor<AppDatabase> with _$GdprDaoMixin {
  GdprDao(super.db);

  /// Log a consent decision.
  Future<int> logConsent(GdprConsentLogsCompanion consent) {
    return into(gdprConsentLogs).insert(consent);
  }

  /// Get all consent logs.
  Future<List<GdprConsentLogData>> getAllConsentLogs() {
    return select(gdprConsentLogs).get();
  }

  /// Get consent logs by type.
  Future<List<GdprConsentLogData>> getConsentLogsByType(String consentType) {
    return (select(gdprConsentLogs)
          ..where((tbl) => tbl.consentType.equals(consentType))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)]))
        .get();
  }

  /// Get latest consent for a specific type.
  Future<GdprConsentLogData?> getLatestConsent(String consentType) {
    return (select(gdprConsentLogs)
          ..where((tbl) => tbl.consentType.equals(consentType))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Check if a specific consent is currently granted.
  Future<bool> isConsentGranted(String consentType) async {
    final latest = await getLatestConsent(consentType);
    return latest?.granted ?? false;
  }
}

/// DAO for sync queue operations.
@DriftAccessor(tables: [SyncQueue])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  /// Add an item to the sync queue.
  Future<int> addToQueue(SyncQueueCompanion item) {
    return into(syncQueue).insert(item);
  }

  /// Get all pending sync items.
  Future<List<SyncQueueData>> getPendingItems() {
    return (select(syncQueue)
          ..where((tbl) => tbl.status.equals('pending'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  /// Get failed sync items.
  Future<List<SyncQueueData>> getFailedItems() {
    return (select(syncQueue)
          ..where((tbl) => tbl.status.equals('failed'))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastAttemptAt)]))
        .get();
  }

  /// Mark a sync item as completed.
  Future<bool> markCompleted(int id) async {
    final rows = await (update(syncQueue)..where((tbl) => tbl.id.equals(id)))
        .write(
          SyncQueueCompanion(
            status: const Value(SyncQueueStatus.completed),
            lastAttemptAt: Value(DateTime.now()),
          ),
        );
    return rows > 0;
  }

  /// Mark a sync item as failed and increment retry count.
  Future<bool> markFailed(int id, int currentRetryCount) async {
    final rows = await (update(syncQueue)..where((tbl) => tbl.id.equals(id)))
        .write(
          SyncQueueCompanion(
            status: const Value(SyncQueueStatus.failed),
            retryCount: Value(currentRetryCount + 1),
            lastAttemptAt: Value(DateTime.now()),
          ),
        );
    return rows > 0;
  }

  /// Mark a sync item as in progress.
  Future<bool> markInProgress(int id) async {
    final rows = await (update(syncQueue)..where((tbl) => tbl.id.equals(id)))
        .write(
          SyncQueueCompanion(
            status: const Value(SyncQueueStatus.inProgress),
            lastAttemptAt: Value(DateTime.now()),
          ),
        );
    return rows > 0;
  }

  /// Delete completed sync items older than a certain date.
  Future<int> deleteCompletedOlderThan(DateTime date) {
    return (delete(syncQueue)..where(
          (tbl) =>
              tbl.status.equals('completed') &
              tbl.createdAt.isSmallerThanValue(date),
        ))
        .go();
  }

  /// Clear all sync queue items (use with caution).
  Future<int> clear() {
    return delete(syncQueue).go();
  }
}
