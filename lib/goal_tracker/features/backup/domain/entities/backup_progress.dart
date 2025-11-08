/// Progress information for backup operations.
class BackupProgress {
  final String stage; // e.g., "Exporting", "Encrypting", "Uploading"
  final double progress; // 0.0 to 1.0

  BackupProgress({required this.stage, required this.progress});
}

