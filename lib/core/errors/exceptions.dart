/// VitalSync — Typed Exception Hierarchy.
///
/// All app-specific exceptions extend [VitalSyncException] which
/// carries a human-readable [message] and an optional [cause].
/// This gives every catch-site a consistent interface for logging
/// and user-facing error strings.
library;

/// Base exception for all VitalSync-specific errors.
///
/// Carries a [message] (user-readable) and an optional wrapped [cause].
/// All concrete exceptions should extend this class.
class VitalSyncException implements Exception {
  const VitalSyncException(this.message, {this.cause});

  /// Human-readable error description.
  final String message;

  /// Optional underlying error that triggered this exception.
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (cause != null) {
      buffer.write(' (cause: $cause)');
    }
    return buffer.toString();
  }
}

class DatabaseException extends VitalSyncException {
  const DatabaseException(super.message, {super.cause});
}

class NetworkException extends VitalSyncException {
  const NetworkException(super.message, {super.cause});
}

class AuthException extends VitalSyncException {
  const AuthException(super.message, {super.cause});
}

class WorkoutInProgressException extends VitalSyncException {
  const WorkoutInProgressException(super.message, {super.cause});
}

class GDPRConsentRequiredException extends VitalSyncException {
  const GDPRConsentRequiredException(super.message, {super.cause});
}

class SyncConflictException extends VitalSyncException {
  const SyncConflictException(super.message, {super.cause});
}

class InsightGenerationException extends VitalSyncException {
  const InsightGenerationException(super.message, {super.cause});
}
