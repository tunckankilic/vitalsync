import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/sync/sync_lifecycle_observer.dart';
import 'package:vitalsync/core/sync/sync_service.dart';

class MockSyncService extends Mock implements SyncService {}

void main() {
  late MockSyncService mockSyncService;
  late SyncLifecycleObserver observer;

  setUp(() {
    mockSyncService = MockSyncService();
    observer = SyncLifecycleObserver(syncService: mockSyncService);

    when(() => mockSyncService.isSyncing).thenReturn(false);
    when(() => mockSyncService.sync()).thenAnswer((_) async {});
  });

  group('SyncLifecycleObserver', () {
    test('flushes the sync queue when the app is paused', () async {
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();

      verify(() => mockSyncService.sync()).called(1);
    });

    test('does not sync on other lifecycle states', () async {
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
      observer.didChangeAppLifecycleState(AppLifecycleState.hidden);
      observer.didChangeAppLifecycleState(AppLifecycleState.detached);
      await pumpEventQueue();

      verifyNever(() => mockSyncService.sync());
    });

    test('does not start a second sync while one is already running', () async {
      when(() => mockSyncService.isSyncing).thenReturn(true);

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();

      verifyNever(() => mockSyncService.sync());
    });

    test('a second pause after the first sync finished flushes again', () async {
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();

      verify(() => mockSyncService.sync()).called(2);
    });

    test('a failing sync neither throws nor blocks', () async {
      when(
        () => mockSyncService.sync(),
      ).thenAnswer((_) async => throw Exception('network down'));

      expect(
        () => observer.didChangeAppLifecycleState(AppLifecycleState.paused),
        returnsNormally,
      );
      // Let the fire-and-forget future complete; its error must be swallowed
      await pumpEventQueue();
    });
  });
}
