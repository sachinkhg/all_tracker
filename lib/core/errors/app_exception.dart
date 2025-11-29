/// Base exception class for all application-level exceptions.
///
/// All custom exceptions in the app should extend this class to ensure
/// consistent error handling and error reporting across the application.
abstract class AppException implements Exception {
  /// A user-friendly error message that can be displayed to users.
  final String message;

  /// Optional detailed error message for debugging/logging purposes.
  final String? details;

  /// Optional stack trace associated with the error.
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.details,
    this.stackTrace,
  });

  @override
  String toString() {
    if (details != null) {
      return '$message\nDetails: $details';
    }
    return message;
  }
}

