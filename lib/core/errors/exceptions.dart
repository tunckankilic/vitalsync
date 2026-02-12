class DatabaseException implements Exception {
  DatabaseException(this.message);
  final String message;
  @override
  String toString() => 'DatabaseException: $message';
}

class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

class WorkoutInProgressException implements Exception {
  WorkoutInProgressException(this.message);
  final String message;
  @override
  String toString() => 'WorkoutInProgressException: $message';
}

class GDPRConsentRequiredException implements Exception {
  GDPRConsentRequiredException(this.message);
  final String message;
  @override
  String toString() => 'GDPRConsentRequiredException: $message';
}

class SyncConflictException implements Exception {
  SyncConflictException(this.message);
  final String message;
  @override
  String toString() => 'SyncConflictException: $message';
}

class InsightGenerationException implements Exception {
  InsightGenerationException(this.message);
  final String message;
  @override
  String toString() => 'InsightGenerationException: $message';
}
