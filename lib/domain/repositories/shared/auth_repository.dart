import '../../models/app_auth_result.dart';
import '../../models/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<AppAuthResult> signIn(String email, String password);
  Future<AppAuthResult> signUp(String email, String password, String name);
  Future<AppAuthResult> signInWithGoogle();
  Future<AppAuthResult> signInWithApple();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> createInitialProfile(AppUser user, String name);
  Future<void> deleteAccount();
}
