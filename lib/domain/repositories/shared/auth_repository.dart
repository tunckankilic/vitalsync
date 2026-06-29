import '../../models/app_auth_result.dart';
import '../../models/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;

  /// Re-checks the persisted session and refreshes [currentUser].
  ///
  /// Unlike the synchronous [currentUser] getter (which only returns the
  /// in-memory cache), this consults the auth provider's persisted session, so
  /// a valid session that hasn't been cached yet — or a genuinely expired one —
  /// is detected reliably. Used by biometric unlock to decide whether a
  /// returning user can proceed. Returns the user when a valid session exists,
  /// otherwise null.
  Future<AppUser?> refreshCurrentUser();

  /// Persists [name] on the auth provider's display-name attribute (Cognito
  /// `name`), so a manually-entered name survives reinstalls and reaches other
  /// devices. Refreshes [currentUser]/[authStateChanges] on success.
  Future<void> updateDisplayName(String name);
  Future<AppAuthResult> signIn(String email, String password);
  Future<AppAuthResult> signUp(String email, String password, String name);
  Future<AppAuthResult> signInWithGoogle();
  Future<AppAuthResult> signInWithApple();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> confirmSignUp(String email, String confirmationCode);
  Future<void> confirmResetPassword(
    String email,
    String code,
    String newPassword,
  );
  Future<void> createInitialProfile(AppUser user, String name);
  Future<void> deleteAccount();
}
