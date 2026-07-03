// Regression test for the sign-out disposal race.
//
// AuthNotifier is auto-disposed and its only watchers are the auth screens.
// Signing out flips the auth state mid-call, the router swaps to the login
// screen, the old watcher unsubscribes and the notifier is torn down while
// signOut is still awaiting. Reading providers through the dead ref after
// that gap threw "Cannot use the Ref of authProvider after it has been
// disposed" — surfacing an error on the login screen AND skipping the
// clearLocalDataOnSignOut wipe entirely.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/core/sync/sync_provider.dart';
import 'package:vitalsync/core/sync/sync_service.dart';
import 'package:vitalsync/domain/models/app_user.dart';

import '../../support/fake_auth_repository.dart';

class _FakeSyncService implements SyncService {
  int clearLocalDataCalls = 0;

  @override
  Future<void> clearLocalDataOnSignOut() async {
    clearLocalDataCalls++;
  }

  // signOut only touches clearLocalDataOnSignOut; anything else is a bug.
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test(
    'signOut completes the local wipe even when the notifier is disposed '
    'mid-flight',
    () async {
      final fakeAuth = FakeAuthRepository(user: const AppUser(id: 'user-1'));
      addTearDown(fakeAuth.dispose);
      final fakeSync = _FakeSyncService();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => fakeAuth),
          syncServiceProvider.overrideWith((ref) => fakeSync),
        ],
      );
      addTearDown(container.dispose);

      // An auth screen watching the notifier — its only listener.
      final subscription = container.listen(authProvider, (_, _) {});

      fakeAuth.signOutGate = Completer<void>();
      final signOutFuture = container
          .read(authProvider.notifier)
          .signOut();

      // Mid sign-out the router swaps screens: the last listener goes away
      // and the auto-disposed notifier is torn down while still awaiting.
      subscription.close();
      await pumpEventQueue();

      fakeAuth.signOutGate!.complete();
      await signOutFuture;

      expect(fakeSync.clearLocalDataCalls, 1);
    },
  );
}
