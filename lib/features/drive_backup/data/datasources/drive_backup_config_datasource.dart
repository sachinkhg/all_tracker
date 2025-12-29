import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/drive_backup_config.dart';

/// Data source for storing Drive backup configuration.
class DriveBackupConfigDataSource {
  static const String _boxName = 'drive_backup_config_box';
  static const String _configKey = 'book_tracker_config';

  /// Get the Hive box for storing config.
  Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  /// Get the current configuration.
  Future<DriveBackupConfig?> getConfig() async {
    final box = await _getBox();
    final data = box.get(_configKey);
    
    if (data == null) return null;

    return DriveBackupConfig(
      folderId: data['folderId'] as String,
      spreadsheetId: data['spreadsheetId'] as String,
      lastBackupTime: data['lastBackupTime'] != null
          ? DateTime.parse(data['lastBackupTime'] as String)
          : null,
      lastRestoreTime: data['lastRestoreTime'] != null
          ? DateTime.parse(data['lastRestoreTime'] as String)
          : null,
      lastSheetSyncTime: data['lastSheetSyncTime'] != null
          ? DateTime.parse(data['lastSheetSyncTime'] as String)
          : null,
    );
  }

  /// Save the configuration.
  Future<void> saveConfig(DriveBackupConfig config) async {
    final box = await _getBox();
    await box.put(_configKey, {
      'folderId': config.folderId,
      'spreadsheetId': config.spreadsheetId,
      'lastBackupTime': config.lastBackupTime?.toIso8601String(),
      'lastRestoreTime': config.lastRestoreTime?.toIso8601String(),
      'lastSheetSyncTime': config.lastSheetSyncTime?.toIso8601String(),
    });
  }

  /// Clear the configuration.
  Future<void> clearConfig() async {
    final box = await _getBox();
    await box.delete(_configKey);
  }
}

