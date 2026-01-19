/// Generic application-level exception
class AppException implements Exception {
  final String message;
  final int? code;
  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}
