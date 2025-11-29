import 'app_exception.dart';

/// Exception thrown when presentation layer operations fail.
///
/// Examples:
/// - UI state inconsistencies
/// - Navigation errors
/// - Form validation errors (that aren't domain-level)
class PresentationException extends AppException {
  const PresentationException(
    super.message, {
    super.details,
    super.stackTrace,
  });
}

