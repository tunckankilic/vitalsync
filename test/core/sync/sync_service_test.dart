import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsync/core/constants/app_constants.dart';
import 'package:vitalsync/core/enums/medication_frequency.dart';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/core/network/connectivity_service.dart';
import 'package:vitalsync/core/sync/cloud_sync_client.dart';
import 'package:vitalsync/core/sync/sync_service.dart';
import 'package:vitalsync/data/local/daos/health/medication_dao.dart';
import 'package:vitalsync/data/local/daos/shared/user_profile_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/domain/models/app_user.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockAppDatabase extends Mock implements AppDatabase {}

class MockSyncDao extends Mock implements SyncDao {}

class MockCloudSyncClient extends Mock implements CloudSyncClient {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockMedicationDao extends Mock implements MedicationDao {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SyncService syncService;
  late MockAppDatabase mockDatabase;
  late MockSyncDao mockSyncDao;
  late MockCloudSyncClient mockCloudClient;
  late MockAuthRepository mockAuth;
  late MockConnectivityService mockConnectivity;

  const user = AppUser(id: 'user-1', email: 'jane@example.com');

  /// Builds a pending insert queue item for [recordId] in [table] whose
  /// local payload carries [localModifiedAt] as its `lastModifiedAt`.
  SyncQueueData pendingInsert({
    int id = 1,
    int recordId = 1,
    String table = 'medications',
    int retryCount = 0,
    required DateTime localModifiedAt,
  }) {
    return SyncQueueData(
      id: id,
      targetTable: table,
      recordId: recordId,
      operation: SyncOperation.insert,
      payload: jsonEncode({
        'id': recordId,
        'lastModifiedAt': localModifiedAt.toIso8601String(),
      }),
      status: SyncQueueStatus.pending,
      retryCount: retryCount,
      createdAt: localModifiedAt,
    );
  }

  /// Builds a pending delete queue item for [recordId] in [table].
  SyncQueueData pendingDelete({
    int id = 1,
    int recordId = 1,
    String table = 'medications',
    required DateTime createdAt,
  }) {
    return SyncQueueData(
      id: id,
      targetTable: table,
      recordId: recordId,
      operation: SyncOperation.delete,
      payload: jsonEncode({'id': recordId}),
      status: SyncQueueStatus.pending,
      retryCount: 0,
      createdAt: createdAt,
    );
  }

  /// Builds a local medication row with a given [lastModifiedAt], used to
  /// exercise pull-side conflict resolution.
  MedicationData medicationRow({
    required int id,
    required DateTime lastModifiedAt,
  }) {
    return MedicationData(
      id: id,
      name: 'Aspirin',
      dosage: '100mg',
      frequency: MedicationFrequency.daily,
      times: '["08:00"]',
      startDate: DateTime(2026, 1, 1),
      color: 0xFF4CAF50,
      isActive: true,
      syncStatus: SyncStatus.synced,
      lastModifiedAt: lastModifiedAt,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockDatabase = MockAppDatabase();
    mockSyncDao = MockSyncDao();
    mockCloudClient = MockCloudSyncClient();
    mockAuth = MockAuthRepository();
    mockConnectivity = MockConnectivityService();

    when(() => mockDatabase.syncDao).thenReturn(mockSyncDao);

    syncService = SyncService(
      database: mockDatabase,
      cloudClient: mockCloudClient,
      auth: mockAuth,
      connectivity: mockConnectivity,
    );
  });

  /// Grants cloud-backup consent and resets per-table sync bookmarks.
  void grantConsent() {
    SharedPreferences.setMockInitialValues({
      AppConstants.prefKeyCloudBackupConsent: true,
    });
  }

  /// Stubs the sync queue DAO state-transition methods (all succeed).
  void stubDaoTransitions() {
    when(() => mockSyncDao.markInProgress(any())).thenAnswer((_) async => true);
    when(() => mockSyncDao.markCompleted(any())).thenAnswer((_) async => true);
    when(
      () => mockSyncDao.markFailed(any(), any()),
    ).thenAnswer((_) async => true);
  }

  /// Makes every collection's remote pull return nothing (empty pull).
  void stubEmptyPull() {
    when(
      () => mockCloudClient.pullRecords(
        userId: any(named: 'userId'),
        collection: any(named: 'collection'),
        since: any(named: 'since'),
      ),
    ).thenAnswer((_) async => <CloudSyncRecord>[]);
  }

  // ── Guard behaviour (offline-first) ───────────────────────────────────────

  group('SyncService.sync guards', () {
    test('skips entirely when cloud backup consent is not granted', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefKeyCloudBackupConsent: false,
      });

      await syncService.sync();

      verifyNever(() => mockConnectivity.isConnected());
      verifyNever(() => mockSyncDao.getPendingItems());
      expect(syncService.isSyncing, isFalse);
    });

    test('skips when offline (consent granted but no connectivity)', () async {
      grantConsent();
      when(() => mockConnectivity.isConnected()).thenAnswer((_) async => false);

      await syncService.sync();

      // Reached connectivity check, but never touched the cloud or the queue.
      verify(() => mockConnectivity.isConnected()).called(1);
      verifyNever(() => mockSyncDao.getPendingItems());
      verifyNever(
        () => mockCloudClient.pushRecord(
          userId: any(named: 'userId'),
          collection: any(named: 'collection'),
          recordId: any(named: 'recordId'),
          data: any(named: 'data'),
        ),
      );
      expect(syncService.isSyncing, isFalse);
    });

    test('skips when user is not authenticated', () async {
      grantConsent();
      when(() => mockConnectivity.isConnected()).thenAnswer((_) async => true);
      when(() => mockAuth.currentUser).thenReturn(null);

      await syncService.sync();

      verifyNever(() => mockSyncDao.getPendingItems());
      expect(syncService.isSyncing, isFalse);
    });
  });

  // ── Push + conflict resolution + retry ────────────────────────────────────

  group('SyncService.sync push path', () {
    setUp(() {
      grantConsent();
      when(() => mockConnectivity.isConnected()).thenAnswer((_) async => true);
      when(() => mockAuth.currentUser).thenReturn(user);
      stubDaoTransitions();
      stubEmptyPull();
    });

    test('pushes a pending record when the remote is older/absent', () async {
      final item = pendingInsert(localModifiedAt: DateTime(2026, 3, 1));
      when(() => mockSyncDao.getPendingItems()).thenAnswer((_) async => [item]);
      when(
        () => mockCloudClient.getRemoteModifiedAt(
          userId: user.id,
          collection: 'medications',
          recordId: '1',
        ),
      ).thenAnswer((_) async => null); // no remote record yet
      when(
        () => mockCloudClient.pushRecord(
          userId: any(named: 'userId'),
          collection: any(named: 'collection'),
          recordId: any(named: 'recordId'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => DateTime(2026, 3, 1));

      await syncService.sync();

      verify(
        () => mockCloudClient.pushRecord(
          userId: user.id,
          collection: 'medications',
          recordId: '1',
          data: any(named: 'data'),
        ),
      ).called(1);
      verify(() => mockSyncDao.markCompleted(item.id)).called(1);
    });

    test(
      'conflict resolution: skips push when remote is newer (last-write-wins)',
      () async {
        final item = pendingInsert(localModifiedAt: DateTime(2026, 3, 1));
        when(
          () => mockSyncDao.getPendingItems(),
        ).thenAnswer((_) async => [item]);
        // Remote modified AFTER the local change → remote wins, skip push.
        when(
          () => mockCloudClient.getRemoteModifiedAt(
            userId: user.id,
            collection: 'medications',
            recordId: '1',
          ),
        ).thenAnswer((_) async => DateTime(2026, 4, 1));

        await syncService.sync();

        verifyNever(
          () => mockCloudClient.pushRecord(
            userId: any(named: 'userId'),
            collection: any(named: 'collection'),
            recordId: any(named: 'recordId'),
            data: any(named: 'data'),
          ),
        );
        // The item is still resolved (marked completed), not left dangling.
        verify(() => mockSyncDao.markCompleted(item.id)).called(1);
      },
    );

    test(
      'retry path: a failed push marks the item failed and not completed',
      () async {
        final item = pendingInsert(localModifiedAt: DateTime(2026, 3, 1));
        when(
          () => mockSyncDao.getPendingItems(),
        ).thenAnswer((_) async => [item]);
        when(
          () => mockCloudClient.getRemoteModifiedAt(
            userId: user.id,
            collection: 'medications',
            recordId: '1',
          ),
        ).thenAnswer((_) async => null);
        when(
          () => mockCloudClient.pushRecord(
            userId: any(named: 'userId'),
            collection: any(named: 'collection'),
            recordId: any(named: 'recordId'),
            data: any(named: 'data'),
          ),
        ).thenThrow(Exception('network blip'));

        await syncService.sync();

        verify(() => mockSyncDao.markInProgress(item.id)).called(1);
        verify(
          () => mockSyncDao.markFailed(item.id, item.retryCount),
        ).called(1);
        verifyNever(() => mockSyncDao.markCompleted(item.id));
      },
    );

    test('delete operation pushes a remote delete and completes', () async {
      final item = pendingDelete(createdAt: DateTime(2026, 3, 1));
      when(() => mockSyncDao.getPendingItems()).thenAnswer((_) async => [item]);
      when(
        () => mockCloudClient.deleteRecord(
          userId: user.id,
          collection: 'medications',
          recordId: '1',
        ),
      ).thenAnswer((_) async {});

      await syncService.sync();

      verify(
        () => mockCloudClient.deleteRecord(
          userId: user.id,
          collection: 'medications',
          recordId: '1',
        ),
      ).called(1);
      verify(() => mockSyncDao.markCompleted(item.id)).called(1);
    });

    test(
      'a failed item does not prevent the next one from completing',
      () async {
        final bad = pendingInsert(
          id: 1,
          recordId: 1,
          localModifiedAt: DateTime(2026, 3, 1),
        );
        final good = pendingInsert(
          id: 2,
          recordId: 2,
          localModifiedAt: DateTime(2026, 3, 2),
        );
        when(
          () => mockSyncDao.getPendingItems(),
        ).thenAnswer((_) async => [bad, good]);
        when(
          () => mockCloudClient.getRemoteModifiedAt(
            userId: user.id,
            collection: 'medications',
            recordId: any(named: 'recordId'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => mockCloudClient.pushRecord(
            userId: user.id,
            collection: 'medications',
            recordId: '1',
            data: any(named: 'data'),
          ),
        ).thenThrow(Exception('network blip'));
        when(
          () => mockCloudClient.pushRecord(
            userId: user.id,
            collection: 'medications',
            recordId: '2',
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => DateTime(2026, 3, 2));

        await syncService.sync();

        verify(() => mockSyncDao.markFailed(bad.id, bad.retryCount)).called(1);
        verify(() => mockSyncDao.markCompleted(good.id)).called(1);
      },
    );

    test(
      'rate limiting: pushes at most one batch (10 items) per cycle',
      () async {
        final items = List.generate(
          12,
          (i) => pendingInsert(
            id: i + 1,
            recordId: i + 1,
            localModifiedAt: DateTime(2026, 3, 1),
          ),
        );
        when(
          () => mockSyncDao.getPendingItems(),
        ).thenAnswer((_) async => items);
        when(
          () => mockCloudClient.getRemoteModifiedAt(
            userId: any(named: 'userId'),
            collection: any(named: 'collection'),
            recordId: any(named: 'recordId'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => mockCloudClient.pushRecord(
            userId: any(named: 'userId'),
            collection: any(named: 'collection'),
            recordId: any(named: 'recordId'),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => DateTime(2026, 3, 1));

        await syncService.sync();

        verify(
          () => mockCloudClient.pushRecord(
            userId: any(named: 'userId'),
            collection: any(named: 'collection'),
            recordId: any(named: 'recordId'),
            data: any(named: 'data'),
          ),
        ).called(10);
      },
    );

    test(
      'conflict resolution: pushes when the remote exists but is older '
      '(local wins)',
      () async {
        final item = pendingInsert(localModifiedAt: DateTime(2026, 3, 10));
        when(
          () => mockSyncDao.getPendingItems(),
        ).thenAnswer((_) async => [item]);
        // Remote record EXISTS but predates the local change → local wins.
        when(
          () => mockCloudClient.getRemoteModifiedAt(
            userId: user.id,
            collection: 'medications',
            recordId: '1',
          ),
        ).thenAnswer((_) async => DateTime(2026, 3, 1));
        when(
          () => mockCloudClient.pushRecord(
            userId: any(named: 'userId'),
            collection: any(named: 'collection'),
            recordId: any(named: 'recordId'),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => DateTime(2026, 3, 10));

        await syncService.sync();

        verify(
          () => mockCloudClient.pushRecord(
            userId: user.id,
            collection: 'medications',
            recordId: '1',
            data: any(named: 'data'),
          ),
        ).called(1);
        verify(() => mockSyncDao.markCompleted(item.id)).called(1);
      },
    );

    test(
      'conditional write rejection: a precondition failure keeps the item '
      'for retry (not completed)',
      () async {
        final item = pendingInsert(localModifiedAt: DateTime(2026, 3, 1));
        when(
          () => mockSyncDao.getPendingItems(),
        ).thenAnswer((_) async => [item]);
        when(
          () => mockCloudClient.getRemoteModifiedAt(
            userId: user.id,
            collection: 'medications',
            recordId: '1',
          ),
        ).thenAnswer((_) async => null);
        // The server rejects the conditional write — RestSyncClient surfaces a
        // non-200 (e.g. precondition failed) as a thrown Exception.
        when(
          () => mockCloudClient.pushRecord(
            userId: any(named: 'userId'),
            collection: any(named: 'collection'),
            recordId: any(named: 'recordId'),
            data: any(named: 'data'),
          ),
        ).thenThrow(Exception('Push failed: precondition failed'));

        // Per-item failures must not abort the whole sync.
        await syncService.sync();

        verify(
          () => mockSyncDao.markFailed(item.id, item.retryCount),
        ).called(1);
        verifyNever(() => mockSyncDao.markCompleted(item.id));
      },
    );

    test(
      'retry exhaustion: an item already at the max retry count is still '
      'marked failed, never completed',
      () async {
        final item = pendingInsert(
          localModifiedAt: DateTime(2026, 3, 1),
          retryCount: AppConstants.syncMaxRetries,
        );
        when(
          () => mockSyncDao.getPendingItems(),
        ).thenAnswer((_) async => [item]);
        when(
          () => mockCloudClient.getRemoteModifiedAt(
            userId: user.id,
            collection: 'medications',
            recordId: '1',
          ),
        ).thenAnswer((_) async => null);
        when(
          () => mockCloudClient.pushRecord(
            userId: any(named: 'userId'),
            collection: any(named: 'collection'),
            recordId: any(named: 'recordId'),
            data: any(named: 'data'),
          ),
        ).thenThrow(Exception('still failing'));

        await syncService.sync();

        // Marked failed with the (already maxed) retry count; the exhaustion
        // branch only logs — it does not complete or drop the item.
        verify(
          () => mockSyncDao.markFailed(item.id, AppConstants.syncMaxRetries),
        ).called(1);
        verifyNever(() => mockSyncDao.markCompleted(item.id));
      },
    );
  });

  // ── Pull path (incremental remote → local) ────────────────────────────────

  group('SyncService.sync pull path', () {
    late MockMedicationDao mockMedicationDao;

    CloudSyncRecord remoteMedication({
      String id = '5',
      required DateTime modifiedAt,
    }) {
      return CloudSyncRecord(
        id: id,
        data: {'id': id, 'lastModifiedAt': modifiedAt.toIso8601String()},
        lastModifiedAt: modifiedAt,
      );
    }

    /// Stubs the medications collection's remote pull to return [records];
    /// every other collection pulls nothing.
    void stubMedicationPull(List<CloudSyncRecord> records) {
      stubEmptyPull();
      when(
        () => mockCloudClient.pullRecords(
          userId: user.id,
          collection: 'medications',
          since: any(named: 'since'),
        ),
      ).thenAnswer((_) async => records);
    }

    setUp(() {
      grantConsent();
      when(() => mockConnectivity.isConnected()).thenAnswer((_) async => true);
      when(() => mockAuth.currentUser).thenReturn(user);
      // No local changes to push — isolate the pull path.
      when(() => mockSyncDao.getPendingItems()).thenAnswer((_) async => []);

      mockMedicationDao = MockMedicationDao();
      when(() => mockDatabase.medicationDao).thenReturn(mockMedicationDao);
      when(
        () => mockMedicationDao.upsertFromRemote(any(), any()),
      ).thenAnswer((_) async {});
    });

    test(
      'applies a remote record locally when there is no local copy',
      () async {
        final modifiedAt = DateTime(2026, 5, 1);
        stubMedicationPull([remoteMedication(id: '5', modifiedAt: modifiedAt)]);
        when(() => mockMedicationDao.getById(5)).thenAnswer((_) async => null);

        await syncService.sync();

        verify(() => mockMedicationDao.upsertFromRemote(5, any())).called(1);
        // Bookmark advanced (user-scoped) so the next pull is incremental.
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getInt('vitalsync_last_sync_${user.id}_medications'),
          modifiedAt.millisecondsSinceEpoch,
        );
      },
    );

    test(
      'pull conflict: skips the local upsert when the local copy is newer',
      () async {
        stubMedicationPull(
          [remoteMedication(id: '5', modifiedAt: DateTime(2026, 3, 1))],
        );
        when(() => mockMedicationDao.getById(5)).thenAnswer(
          (_) async =>
              medicationRow(id: 5, lastModifiedAt: DateTime(2026, 4, 1)),
        );

        await syncService.sync();

        verifyNever(() => mockMedicationDao.upsertFromRemote(any(), any()));
      },
    );

    test('ignores a remote record whose id is not numeric', () async {
      stubMedicationPull(
        [remoteMedication(id: 'not-an-int', modifiedAt: DateTime(2026, 5, 1))],
      );

      await syncService.sync();

      verifyNever(() => mockMedicationDao.getById(any()));
      verifyNever(() => mockMedicationDao.upsertFromRemote(any(), any()));
    });

    test(
      'a failing upsert on one record does not abort the rest of the batch',
      () async {
        stubMedicationPull([
          remoteMedication(id: '1', modifiedAt: DateTime(2026, 5, 1)),
          remoteMedication(id: '2', modifiedAt: DateTime(2026, 5, 2)),
        ]);
        when(
          () => mockMedicationDao.getById(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockMedicationDao.upsertFromRemote(1, any()),
        ).thenThrow(Exception('disk full'));
        when(
          () => mockMedicationDao.upsertFromRemote(2, any()),
        ).thenAnswer((_) async {});

        await syncService.sync();

        // Record 2 is still applied even though record 1 threw.
        verify(() => mockMedicationDao.upsertFromRemote(2, any())).called(1);
      },
    );
  });

  // ── Re-entrancy guard ──────────────────────────────────────────────────────

  group('SyncService.sync re-entrancy', () {
    setUp(() {
      grantConsent();
      when(() => mockConnectivity.isConnected()).thenAnswer((_) async => true);
      when(() => mockAuth.currentUser).thenReturn(user);
      stubDaoTransitions();
      stubEmptyPull();
    });

    test('a second sync() while one is in progress is skipped', () async {
      // Park the first sync inside the push step until we release the gate.
      final gate = Completer<List<SyncQueueData>>();
      when(() => mockSyncDao.getPendingItems()).thenAnswer((_) => gate.future);

      final first = syncService.sync();

      // Wait until the service has actually entered the syncing state.
      var guard = 0;
      while (!syncService.isSyncing && guard++ < 1000) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(syncService.isSyncing, isTrue);

      // A concurrent call must bail out immediately, never re-reading the queue.
      await syncService.sync();
      verify(() => mockSyncDao.getPendingItems()).called(1);

      // Release the first sync and let it finish cleanly.
      gate.complete(<SyncQueueData>[]);
      await first;
      expect(syncService.isSyncing, isFalse);
    });
  });

  // ── Auto-sync (offline → online transition) ───────────────────────────────

  group('SyncService auto-sync (offline → online)', () {
    late StreamController<bool> connectivityController;

    setUp(() {
      grantConsent();
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => mockConnectivity.isConnected()).thenAnswer((_) async => true);
      stubDaoTransitions();
      stubEmptyPull();

      connectivityController = StreamController<bool>.broadcast();
      when(
        () => mockConnectivity.connectivityStream,
      ).thenAnswer((_) => connectivityController.stream);
    });

    tearDown(() async {
      await syncService.stopAutoSync();
      await connectivityController.close();
    });

    // The auto-sync listener fires sync() as fire-and-forget; spin the event
    // loop enough times to let that async chain run to completion.
    Future<void> flushEventQueue() async {
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('drains the pending queue when connectivity returns', () async {
      final item = pendingInsert(localModifiedAt: DateTime(2026, 3, 1));
      when(() => mockSyncDao.getPendingItems()).thenAnswer((_) async => [item]);
      when(
        () => mockCloudClient.getRemoteModifiedAt(
          userId: user.id,
          collection: 'medications',
          recordId: '1',
        ),
      ).thenAnswer((_) async => null);
      when(
        () => mockCloudClient.pushRecord(
          userId: any(named: 'userId'),
          collection: any(named: 'collection'),
          recordId: any(named: 'recordId'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => DateTime(2026, 3, 1));

      syncService.startAutoSync();

      // Still offline: a `false` event must NOT trigger a sync.
      connectivityController.add(false);
      await flushEventQueue();
      verifyNever(() => mockSyncDao.getPendingItems());

      // Transition to online: the queued change is pushed and completed.
      connectivityController.add(true);
      await flushEventQueue();

      verify(() => mockSyncDao.getPendingItems()).called(1);
      verify(
        () => mockCloudClient.pushRecord(
          userId: user.id,
          collection: 'medications',
          recordId: '1',
          data: any(named: 'data'),
        ),
      ).called(1);
      verify(() => mockSyncDao.markCompleted(item.id)).called(1);
      expect(syncService.isSyncing, isFalse);
    });
  });

  // ── Sign-out cleanup (account switch / privacy) ────────────────────────────

  group('SyncService.clearLocalDataOnSignOut', () {
    test(
        'wipes the local DB and resets every user-scoped bookmark when a '
        'cloud backup exists', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefKeyCloudBackupConsent: true,
        'vitalsync_last_sync_user-1_medications': 123,
        'vitalsync_last_sync_user-2_symptoms': 456,
      });
      when(() => mockDatabase.deleteAllData()).thenAnswer((_) async {});

      await syncService.clearLocalDataOnSignOut();

      verify(() => mockDatabase.deleteAllData()).called(1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('vitalsync_last_sync_user-1_medications'), isNull);
      expect(prefs.getInt('vitalsync_last_sync_user-2_symptoms'), isNull);
    });

    test('without consent keeps both the local DB and its bookmarks',
        () async {
      // No cloud backup: wiping would destroy the user's only copy of the data,
      // and the bookmark must stay consistent with the retained DB.
      SharedPreferences.setMockInitialValues({
        AppConstants.prefKeyCloudBackupConsent: false,
        'vitalsync_last_sync_user-1_symptoms': 456,
      });

      await syncService.clearLocalDataOnSignOut();

      verifyNever(() => mockDatabase.deleteAllData());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('vitalsync_last_sync_user-1_symptoms'), 456);
    });
  });
}
