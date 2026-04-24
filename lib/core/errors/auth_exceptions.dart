/// VitalSync — Authentication custom exceptions.
library;

abstract class AppAuthException implements Exception {
  const AppAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class EmailNotVerifiedException extends AppAuthException {
  const EmailNotVerifiedException(super.message);
}

class SignInFailedException extends AppAuthException {
  const SignInFailedException(super.message);
}

class SignUpFailedException extends AppAuthException {
  const SignUpFailedException(super.message);
}

class ConfirmationFailedException extends AppAuthException {
  const ConfirmationFailedException(super.message);
}
