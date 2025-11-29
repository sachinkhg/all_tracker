import 'app_exception.dart';
import 'data_exception.dart';
import 'domain_exception.dart';
import 'presentation_exception.dart';

/// Maps exceptions to user-friendly error messages.
///
/// This class provides a centralized way to convert technical exceptions
/// into messages that can be displayed to users in the UI.
class ErrorMapper {
  /// Maps an exception to a user-friendly message.
  ///
  /// Returns a string that can be safely displayed to users.
  /// For unknown exceptions, returns a generic error message.
  static String toUserMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }

    // Handle common Flutter/Dart exceptions
    if (error is FormatException) {
      return 'Invalid data format. Please check your input.';
    }

    if (error is ArgumentError) {
      return 'Invalid input provided.';
    }

    if (error is StateError) {
      return 'An unexpected error occurred. Please try again.';
    }

    // Generic fallback for unknown exceptions
    return 'An unexpected error occurred. Please try again later.';
  }

  /// Maps an exception to a detailed error message for logging/debugging.
  ///
  /// Returns a string with full error details including stack trace if available.
  static String toDetailedMessage(Object error, [StackTrace? stackTrace]) {
    final buffer = StringBuffer();

    if (error is AppException) {
      buffer.writeln('Error: ${error.message}');
      if (error.details != null) {
        buffer.writeln('Details: ${error.details}');
      }
      if (error.stackTrace != null) {
        buffer.writeln('StackTrace: ${error.stackTrace}');
      } else if (stackTrace != null) {
        buffer.writeln('StackTrace: $stackTrace');
      }
    } else {
      buffer.writeln('Error: $error');
      if (stackTrace != null) {
        buffer.writeln('StackTrace: $stackTrace');
      }
    }

    return buffer.toString();
  }

  /// Determines if an error is recoverable (can be retried).
  static bool isRecoverable(Object error) {
    if (error is DataException) {
      // Data exceptions might be recoverable (network issues, temporary failures)
      return true;
    }

    if (error is DomainException) {
      // Domain exceptions are usually not recoverable without user action
      return false;
    }

    if (error is PresentationException) {
      // Presentation exceptions might be recoverable
      return true;
    }

    // Default to not recoverable for unknown exceptions
    return false;
  }
}

