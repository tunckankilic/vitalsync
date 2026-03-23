/// VitalSync — Auth Riverpod Providers.
///
/// Auth integration (provider-agnostic):
///  - authStateProvider (stream from AuthRepository.authStateChanges)
///  - currentUserProvider (UserProfile from local DB)
///  - authNotifier (signIn, signUp, signInWithGoogle, signInWithApple, signOut, resetPassword).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/shared/user_profile.dart';
import '../../domain/models/app_auth_result.dart';
import '../../domain/models/app_user.dart';
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

/// Stream provider for auth state changes (provider-agnostic)
@riverpod
Stream<AppUser?> authState(Ref ref) {
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

    return result.value as AppAuthResult;
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

  /// Reset password (sends verification code to email)
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

  /// Confirm sign-up with email verification code
  Future<void> confirmSignUp(String email, String confirmationCode) async {
    state = const AsyncValue.loading();

    final authRepo = ref.read(authRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await authRepo.confirmSignUp(email, confirmationCode);
    });

    if (state.hasError) {
      throw state.error!;
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

    state = await AsyncValue.guard(() async {
      await authRepo.confirmResetPassword(email, code, newPassword);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }
}
