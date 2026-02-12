/// VitalSync — Shared Abstract Repositories.
///
/// Defines interfaces for user and authentication repositories.
library;

/// Abstract repository for user profile operations.
///
/// Manages user profile data and GDPR operations.
/// Full method signatures from Prompt 2.3.
abstract class UserRepository {
  // TODO: Implement in Prompt 2.3 with full method signatures
  // Example methods:
  // Future<UserProfile?> getCurrentUser();
  // Future<void> saveProfile(UserProfile profile);
  // Future<void> updateProfile(UserProfile profile);
  // Future<String> exportAllData(); // GDPR data export
  // Future<void> deleteAllData(); // GDPR right to deletion
}

/// Abstract repository for authentication operations.
///
/// Manages user authentication with Firebase Auth.
/// Full method signatures from Prompt 2.3.
abstract class AuthRepository {
  // TODO: Implement in Prompt 2.3 with full method signatures
  // Example methods:
  // Future<User?> signIn(String email, String password);
  // Future<User?> signUp(String email, String password);
  // Future<User?> signInWithGoogle();
  // Future<void> signOut();
  // Future<void> resetPassword(String email);
  // Stream<User?> authStateChanges();
}
