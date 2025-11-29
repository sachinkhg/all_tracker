import 'app_exception.dart';

/// Exception thrown when data layer operations fail.
///
/// Examples:
/// - Database/Hive operations fail
/// - Data serialization/deserialization errors
/// - Network request failures (if remote data sources are added)
class DataException extends AppException {
  const DataException(
    super.message, {
    super.details,
    super.stackTrace,
  });
}

/// Exception thrown when a requested entity is not found.
class EntityNotFoundException extends DataException {
  final String entityType;
  final String entityId;

  const EntityNotFoundException(
    this.entityType,
    this.entityId, {
    super.details,
    super.stackTrace,
  }) : super('$entityType with id "$entityId" not found');
}

/// Exception thrown when data validation fails.
class DataValidationException extends DataException {
  const DataValidationException(
    super.message, {
    super.details,
    super.stackTrace,
  });
}

/// Exception thrown when data persistence operations fail.
class PersistenceException extends DataException {
  const PersistenceException(
    super.message, {
    super.details,
    super.stackTrace,
  });
}

