/// VitalSync — Auth Riverpod Providers.
///
/// Auth integration (provider-agnostic):
///  - authStateProvider (stream from AuthRepository.authStateChanges)
///  - currentUserProvider (UserProfile from local DB)
///  - authNotifier (signIn, signUp, signInWithGoogle, signInWithApple, signOut, resetPassword).
library;

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/database.dart';
import '../../domain/entities/shared/user_profile.dart';
import '../../domain/models/app_auth_result.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/shared/auth_repository.dart';
import '../../domain/repositories/shared/user_repository.dart';
import '../analytics/analytics_service.dart';
import '../di/injection_container.dart';
import '../sync/sync_provider.dart';

part 'auth_provider.g.dart';

/// Provider for the AuthRepository instance
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return getIt<AuthRepository>();
}

/// Provider for the UserRepository instance
@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) {
  return getIt<UserRepository>();
}

/// Provider for the AnalyticsService instance
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  return getIt<AnalyticsService>();
}

/// Stream provider for auth state changes (provider-agnostic).
///
/// Emits the repository's cached user first: the underlying stream is a plain
/// broadcast controller that does not replay past events, so a subscriber that
/// starts after sign-in — this provider is auto-disposed and is typically
/// (re)created when the profile screens open — would otherwise see nothing
/// until the next auth event and render the user as signed-out.
@riverpod
Stream<AppUser?> authState(Ref ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  yield repository.currentUser;
  yield* repository.authStateChanges;
}

/// Provider for current UserProfile from local database
@riverpod
Future<UserProfile?> currentUser(Ref ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getCurrentUser();
}

/// Notifier for authentication operations
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Fire-and-forget cloud pull after a successful login, so a returning
  /// user's backup lands immediately instead of waiting for a connectivity
  /// change or app resume. [SyncService.sync] self-guards on consent,
  /// connectivity and auth state, so this is safe to call unconditionally.
  void _triggerPostLoginSync() {
    unawaited(
      ref.read(syncServiceProvider).sync().catchError((Object _) {
        // Non-fatal: auto-sync retries on the next trigger.
      }),
    );
  }

  /// Restores the default catalogue (exercises, workout templates, achievements)
  /// after login when the local database is empty — e.g. it was wiped on a
  /// previous sign-out (consent-gated) or lost to a reinstall. Fire-and-forget
  /// and idempotent: [seedDefaultDataIfEmpty] seeds only when the exercises
  /// table is empty, so a user who deleted exercises one-by-one keeps that
  /// choice and a returning user with data is left untouched. Without this, a
  /// re-seed would only occur on the next cold start, leaving an in-session
  /// sign-out → sign-in with an empty exercise library and no saved templates.
  ///
  /// Best-effort: like the post-login sync, any failure (including an
  /// unavailable database) is swallowed so it can never break authentication.
  void _ensureSeedData() {
    unawaited(
      Future(() => seedDefaultDataIfEmpty(getIt<AppDatabase>())).catchError((
        Object _,
      ) {
        // Non-fatal: catalogue restore is best-effort, never blocks login.
      }),
    );
  }

  /// Sign in with email and password
  Future<AppAuthResult> signIn(String email, String password) async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      final authResult = await authRepo.signIn(email, password);
      return authResult;
    });

    state = result.when(
      data: (_) => const AsyncValue.data(null),
      error: AsyncValue.error,
      loading: () => const AsyncValue.loading(),
    );

    if (result.hasError) {
      throw result.error!;
    }

    _ensureSeedData();
    _triggerPostLoginSync();
    return result.value as AppAuthResult;
  }

  /// Sign up with email, password, and name
  Future<AppAuthResult> signUp(
    String email,
    String password,
    String name,
  ) async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      final authResult = await authRepo.signUp(email, password, name);
      return authResult;
    });

    state = result.when(
      data: (_) => const AsyncValue.data(null),
      error: AsyncValue.error,
      loading: () => const AsyncValue.loading(),
    );

    if (result.hasError) {
      throw result.error!;
    }

    return result.value as AppAuthResult;
  }

  /// Sign in with Google
  Future<AppAuthResult> signInWithGoogle() async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      final authResult = await authRepo.signInWithGoogle();
      return authResult;
    });

    state = result.when(
      data: (_) => const AsyncValue.data(null),
      error: AsyncValue.error,
      loading: () => const AsyncValue.loading(),
    );

    if (result.hasError) {
      throw result.error!;
    }

    _ensureSeedData();
    _triggerPostLoginSync();
    return result.value as AppAuthResult;
  }

  /// Sign in with Apple
  Future<AppAuthResult> signInWithApple() async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      final authResult = await authRepo.signInWithApple();
      return authResult;
    });

    state = result.when(
      data: (_) => const AsyncValue.data(null),
      error: AsyncValue.error,
      loading: () => const AsyncValue.loading(),
    );

    if (result.hasError) {
      throw result.error!;
    }

    _ensureSeedData();
    _triggerPostLoginSync();
    return result.value as AppAuthResult;
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      await authRepo.signOut();
      // Clear device-local data so the next account starts clean and pulls its
      // own backup fresh. Wipe is consent-gated inside the sync service.
      await ref.read(syncServiceProvider).clearLocalDataOnSignOut();
    });
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }

  /// Reset password (sends verification code to email)
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      await authRepo.resetPassword(email);
    });
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }

  /// Confirm sign-up with email verification code
  Future<void> confirmSignUp(String email, String confirmationCode) async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      await authRepo.confirmSignUp(email, confirmationCode);
    });
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }

  /// Confirm password reset with code and new password
  Future<void> confirmResetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      await authRepo.confirmResetPassword(email, code, newPassword);
    });
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }
}
