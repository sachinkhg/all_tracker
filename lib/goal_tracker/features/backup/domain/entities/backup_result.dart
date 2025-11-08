/// Result of a backup operation.
sealed class BackupResult {}

/// Successful backup result.
class BackupSuccess extends BackupResult {
  final String backupId;
  final int sizeBytes;

  BackupSuccess({required this.backupId, required this.sizeBytes});
}

/// Failed backup result.
class BackupFailure extends BackupResult {
  final String error;

  BackupFailure({required this.error});
}

