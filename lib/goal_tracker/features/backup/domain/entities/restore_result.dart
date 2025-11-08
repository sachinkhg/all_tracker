/// Result of a restore operation.
sealed class RestoreResult {}

/// Successful restore result.
class RestoreSuccess extends RestoreResult {}

/// Failed restore result.
class RestoreFailure extends RestoreResult {
  final String error;

  RestoreFailure({required this.error});
}

