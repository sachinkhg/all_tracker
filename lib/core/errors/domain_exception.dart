import 'app_exception.dart';

/// Exception thrown when domain layer business rules are violated.
///
/// Examples:
/// - Invalid entity state
/// - Business rule violations
/// - Use case preconditions not met
class DomainException extends AppException {
  const DomainException(
    super.message, {
    super.details,
    super.stackTrace,
  });
}

/// Exception thrown when a business rule is violated.
class BusinessRuleViolationException extends DomainException {
  const BusinessRuleViolationException(
    super.message, {
    super.details,
    super.stackTrace,
  });
}

