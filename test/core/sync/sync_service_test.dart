import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsync/core/constants/app_constants.dart';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/core/network/connectivity_service.dart';
import 'package:vitalsync/core/sync/cloud_sync_client.dart';
import 'package:vitalsync/core/sync/sync_service.dart';
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
      retryCount: 0,
      createdAt: localModifiedAt,
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
  });
}
