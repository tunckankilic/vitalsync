// Regression tests for the authState provider's initial emission.
//
// The repository's authStateChanges is a broadcast stream that does not
// replay: a subscriber that starts after sign-in receives nothing until the
// next auth event. authState is auto-disposed and typically (re)created when
// the profile screens open, so without an initial emission of the cached user
// those screens rendered a signed-in user as signed-out ("User" / no email).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/domain/models/app_user.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  group('authState', () {
    // Builds a container around [fake] and keeps the auto-disposed provider
    // alive with a persistent listener, as the profile screens do via watch.
    (ProviderContainer, ProviderSubscription<AsyncValue<AppUser?>>) listen(
      FakeAuthRepository fake,
    ) {
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWith((ref) => fake)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(authStateProvider, (_, _) {});
      addTearDown(subscription.close);
      return (container, subscription);
    }

    test('emits the cached user immediately to a late subscriber', () async {
      final fake = FakeAuthRepository(
        user: const AppUser(
          id: 'user-1',
          email: 'ada@example.com',
          displayName: 'Ada Lovelace',
        ),
      );
      addTearDown(fake.dispose);

      // Simulates the profile screen opening long after sign-in: the provider
      // subscribes only now, and no further auth event is ever pushed.
      final (container, _) = listen(fake);

      final first = await container.read(authStateProvider.future);
      expect(first?.displayName, 'Ada Lovelace');
      expect(first?.email, 'ada@example.com');
    });

    test('emits null immediately when signed out', () async {
      final fake = FakeAuthRepository();
      addTearDown(fake.dispose);

      final (container, _) = listen(fake);

      final first = await container.read(authStateProvider.future);
      expect(first, isNull);
    });

    test('still forwards subsequent auth events', () async {
      final fake = FakeAuthRepository();
      addTearDown(fake.dispose);

      final (container, subscription) = listen(fake);

      expect(await container.read(authStateProvider.future), isNull);
      await pumpEventQueue();

      fake.emit(const AppUser(id: 'user-2', email: 'new@example.com'));
      await pumpEventQueue();

      expect(subscription.read().value?.id, 'user-2');
    });
  });
}
