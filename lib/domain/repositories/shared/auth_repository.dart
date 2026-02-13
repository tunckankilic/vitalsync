import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<UserCredential> signIn(String email, String password);
  Future<UserCredential> signUp(String email, String password, String name);
  Future<UserCredential> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> createInitialProfile(User user, String name);
}
