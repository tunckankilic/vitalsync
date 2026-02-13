/// VitalSync — Auth Riverpod Providers.
///
/// Firebase Auth integration:
///  - authStateProvider (stream from FirebaseAuth.authStateChanges)
///  - currentUserProvider (UserProfile from local DB)
///  - authNotifier (signIn, signUp, signInWithGoogle, signInWithApple, signOut, resetPassword).
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/shared/user_profile.dart';
import '../../domain/repositories/shared/auth_repository.dart';
import '../../domain/repositories/shared/user_repository.dart';
import '../analytics/analytics_service.dart';
import '../di/injection_container.dart';

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

/// Stream provider for Firebase Auth state changes
@riverpod
Stream<User?> authState(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
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

  /// Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      final credential = await authRepo.signIn(email, password);
      return credential;
    });

    state = result.when(
      data: (_) => const AsyncValue.data(null),
      error: AsyncValue.error,
      loading: () => const AsyncValue.loading(),
    );

    if (result.hasError) {
      throw result.error!;
    }

    return result.value as UserCredential;
  }

  /// Sign up with email, password, and name
  Future<UserCredential> signUp(
    String email,
    String password,
    String name,
  ) async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      final credential = await authRepo.signUp(email, password, name);
      return credential;
    });

    state = result.when(
      data: (_) => const AsyncValue.data(null),
      error: AsyncValue.error,
      loading: () => const AsyncValue.loading(),
    );

    if (result.hasError) {
      throw result.error!;
    }

    return result.value as UserCredential;
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      final credential = await authRepo.signInWithGoogle();
      return credential;
    });

    state = result.when(
      data: (_) => const AsyncValue.data(null),
      error: AsyncValue.error,
      loading: () => const AsyncValue.loading(),
    );

    if (result.hasError) {
      throw result.error!;
    }

    return result.value as UserCredential;
  }

  /// Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      final credential = await authRepo.signInWithApple();
      return credential;
    });

    state = result.when(
      data: (_) => const AsyncValue.data(null),
      error: AsyncValue.error,
      loading: () => const AsyncValue.loading(),
    );

    if (result.hasError) {
      throw result.error!;
    }

    return result.value as UserCredential;
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await authRepo.signOut();
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await authRepo.resetPassword(email);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }
}
