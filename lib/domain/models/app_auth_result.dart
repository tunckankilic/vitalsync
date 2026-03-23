/// VitalSync — Domain-agnostic authentication result.
///
/// Replaces direct usage of `firebase_auth.UserCredential` in the domain layer.
/// Wraps the authenticated user and metadata about the sign-in operation.
library;

import 'app_user.dart';

/// Result of an authentication operation (sign-in, sign-up).
///
/// This is the domain model that replaces `firebase_auth.UserCredential`.
/// Contains the authenticated user and whether this is a new registration.
class AppAuthResult {
  const AppAuthResult({
    required this.user,
    this.isNewUser = false,
  });

  /// The authenticated user.
  final AppUser user;

  /// Whether this sign-in created a new user account.
  final bool isNewUser;

  @override
  String toString() =>
      'AppAuthResult(user: ${user.id}, isNewUser: $isNewUser)';
}
