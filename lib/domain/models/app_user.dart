/// VitalSync — Domain-agnostic user model.
///
/// Domain-agnostic user model, independent of any auth provider.
/// Can be constructed from any auth backend (Cognito, custom, etc.).
library;

/// Represents an authenticated user in the domain layer.
///
/// All auth consumers (providers, UI, services) should use this
/// instead of any provider-specific user type.
class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.emailVerified = false,
    this.photoUrl,
    this.createdAt,
    this.lastSignInAt,
  });

  /// Unique user identifier (Cognito sub, etc.)
  final String id;

  /// User's email address.
  final String? email;

  /// User's display name.
  final String? displayName;

  /// Whether the user's email has been verified.
  final bool emailVerified;

  /// URL to the user's profile photo.
  final String? photoUrl;

  /// When the user account was created.
  final DateTime? createdAt;

  /// When the user last signed in.
  final DateTime? lastSignInAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppUser(id: $id, email: $email, name: $displayName)';
}
