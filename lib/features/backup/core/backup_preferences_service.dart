import 'package:hive_flutter/hive_flutter.dart';
import '../../../../trackers/goal_tracker/core/constants.dart';
import '../domain/entities/backup_mode.dart';

/// Service for managing backup preferences.
/// 
/// Stores backup settings in Hive for persistence across app launches.
class BackupPreferencesService {
  Box get _box => Hive.box(backupPreferencesBoxName);

  /// Check if automatic backups are enabled.
  bool get autoBackupEnabled {
    return _box.get('autoBackupEnabled', defaultValue: false) as bool;
  }

  /// Set automatic backup enabled state.
  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _box.put('autoBackupEnabled', enabled);
  }

  /// Get the backup encryption mode.
  BackupMode get backupMode {
    final modeStr = _box.get('backupMode', defaultValue: 'e2ee') as String;
    return modeStr == 'e2ee' ? BackupMode.e2ee : BackupMode.deviceKey;
  }

  /// Set the backup encryption mode.
  Future<void> setBackupMode(BackupMode mode) async {
    await _box.put('backupMode', mode == BackupMode.e2ee ? 'e2ee' : 'deviceKey');
  }

  /// Get the retention count (number of backups to keep).
  int get retentionCount {
    return _box.get('retentionCount', defaultValue: 3) as int;
  }

  /// Set the retention count.
  Future<void> setRetentionCount(int count) async {
    await _box.put('retentionCount', count);
  }

  /// Get the last backup time.
  DateTime? get lastBackupTime {
    final timestamp = _box.get('lastBackupTime');
    return timestamp != null ? DateTime.parse(timestamp as String) : null;
  }

  /// Set the last backup time.
  Future<void> setLastBackupTime(DateTime time) async {
    await _box.put('lastBackupTime', time.toUtc().toIso8601String());
  }

  /// Get the last restore time (when we last restored from a backup).
  DateTime? get lastRestoreTime {
    final timestamp = _box.get('lastRestoreTime');
    return timestamp != null ? DateTime.parse(timestamp as String) : null;
  }

  /// Set the last restore time.
  Future<void> setLastRestoreTime(DateTime time) async {
    await _box.put('lastRestoreTime', time.toUtc().toIso8601String());
  }

  /// Check if automatic backup should run now.
  /// 
  /// Returns true if:
  /// - Auto backup is enabled
  /// No longer checks for 24-hour interval - backups are triggered by app lifecycle events
  bool shouldRunAutomaticBackup() {
    return autoBackupEnabled;
  }
}
