import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsync/core/errors/exceptions.dart';
import 'package:vitalsync/core/gdpr/gdpr_manager.dart';
import 'package:vitalsync/core/sync/cloud_sync_client.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/domain/models/app_user.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockAppDatabase extends Mock implements AppDatabase {}

class MockCloudSyncClient extends Mock implements CloudSyncClient {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GDPRManager manager;
  late MockAppDatabase mockDatabase;
  late MockCloudSyncClient mockCloudClient;
  late MockAuthRepository mockAuth;
  late SharedPreferences prefs;

  const user = AppUser(id: 'user-1', email: 'jane@example.com');

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'some_setting': true});
    prefs = await SharedPreferences.getInstance();
    mockDatabase = MockAppDatabase();
    mockCloudClient = MockCloudSyncClient();
    mockAuth = MockAuthRepository();

    manager = GDPRManager(
      prefs: prefs,
      cloudClient: mockCloudClient,
      auth: mockAuth,
      database: mockDatabase,
    );
  });

  group('GDPRManager.deleteAllUserData', () {
    test('throws and touches nothing when no user is authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      await expectLater(
        manager.deleteAllUserData(),
        throwsA(isA<AccountDeletionException>()),
      );

      verifyNever(
        () => mockCloudClient.deleteAllUserData(
          userId: any(named: 'userId'),
          collections: any(named: 'collections'),
        ),
      );
      verifyNever(() => mockDatabase.deleteAllData());
      verifyNever(() => mockAuth.deleteAccount());
    });

    test(
      'happy path deletes cloud, then local DB, then the account — in order',
      () async {
        when(() => mockAuth.currentUser).thenReturn(user);
        when(
          () => mockCloudClient.deleteAllUserData(
            userId: any(named: 'userId'),
            collections: any(named: 'collections'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockDatabase.deleteAllData()).thenAnswer((_) async {});
        when(() => mockAuth.deleteAccount()).thenAnswer((_) async {});

        await manager.deleteAllUserData();

        // Cloud deletion must happen first (while the session token is valid),
        // the account deletion last (it invalidates the session).
        verifyInOrder([
          () => mockCloudClient.deleteAllUserData(
            userId: user.id,
            collections: any(named: 'collections'),
          ),
          () => mockDatabase.deleteAllData(),
          () => mockAuth.deleteAccount(),
        ]);

        // SharedPreferences were wiped as part of the erasure.
        expect(prefs.getBool('some_setting'), isNull);
      },
    );

    test(
      'aborts without deleting local data or the account when cloud delete '
      'fails (no orphaned server data)',
      () async {
        when(() => mockAuth.currentUser).thenReturn(user);
        when(
          () => mockCloudClient.deleteAllUserData(
            userId: any(named: 'userId'),
            collections: any(named: 'collections'),
          ),
        ).thenThrow(Exception('offline'));

        await expectLater(
          manager.deleteAllUserData(),
          throwsA(isA<AccountDeletionException>()),
        );

        // Nothing destructive ran after the cloud failure.
        verifyNever(() => mockDatabase.deleteAllData());
        verifyNever(() => mockAuth.deleteAccount());
        // Local prefs are left intact so the user can retry.
        expect(prefs.getBool('some_setting'), isTrue);
      },
    );
  });
}
