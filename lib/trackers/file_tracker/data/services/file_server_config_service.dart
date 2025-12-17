import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/file_server_config.dart';
import '../models/file_server_config_model.dart';
import '../../core/constants.dart';

/// Service for managing multiple file server configurations.
///
/// Stores server configs by their server name, allowing multiple servers
/// to be configured and switched between.
class FileServerConfigService {
  Box<FileServerConfigModel>? _box;
  Box<String>? _activeServerBox;

  /// Gets the Hive box for server configurations.
  Future<Box<FileServerConfigModel>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<FileServerConfigModel>(fileTrackerConfigBoxName);
    }
    return _box!;
  }

  /// Gets the Hive box for storing active server name.
  Future<Box<String>> _getActiveServerBox() async {
    if (_activeServerBox == null || !_activeServerBox!.isOpen) {
      _activeServerBox = await Hive.openBox<String>('${fileTrackerConfigBoxName}_active');
    }
    return _activeServerBox!;
  }

  /// Saves or updates a server configuration.
  ///
  /// The config is stored using its serverName as the key.
  Future<void> saveConfig(FileServerConfig config) async {
    final box = await _getBox();
    final model = FileServerConfigModel.fromEntity(config);
    await box.put(config.serverName, model);
    // Ensure data is persisted to disk
    await box.flush();
    // Verify save
    final savedModel = box.get(config.serverName);
    if (savedModel == null) {
      throw Exception('Failed to save server configuration: ${config.serverName}');
    }
  }

  /// Gets a server configuration by name.
  ///
  /// Returns null if no config exists with the given name.
  Future<FileServerConfig?> getConfig(String serverName) async {
    final box = await _getBox();
    final model = box.get(serverName);
    return model?.toEntity();
  }

  /// Gets all saved server configurations.
  /// Also migrates old data format if found.
  Future<List<FileServerConfig>> getAllConfigs() async {
    final box = await _getBox();
    
    // Check for old data format (stored with key 'config')
    if (box.containsKey('config')) {
      await _migrateOldConfig(box);
    }
    
    // Filter out the 'config' key if it still exists (shouldn't happen after migration)
    final configs = <FileServerConfig>[];
    for (final key in box.keys) {
      if (key != 'config') {
        final model = box.get(key);
        if (model != null) {
          configs.add(model.toEntity());
        }
      }
    }
    
    return configs;
  }

  /// Migrates old config format (stored with key 'config') to new format.
  Future<void> _migrateOldConfig(Box<FileServerConfigModel> box) async {
    try {
      final oldModel = box.get('config');
      if (oldModel != null) {
        final config = oldModel.toEntity();
        // Save with new format (using serverName as key)
        await box.put(config.serverName, oldModel);
        // Delete old entry
        await box.delete('config');
      }
    } catch (e) {
      // Migration failed, but don't crash the app
      // The old data will be ignored
    }
  }

  /// Gets all server names.
  Future<List<String>> getAllServerNames() async {
    final box = await _getBox();
    return box.keys.cast<String>().toList();
  }

  /// Deletes a server configuration by name.
  /// Simply deletes the record if it exists, no checks or verification.
  Future<void> deleteConfig(String serverName) async {
    print('[FILE_TRACKER_SERVICE] deleteConfig called for: $serverName');
    try {
      final box = await _getBox();
      print('[FILE_TRACKER_SERVICE] Box opened, checking if server exists...');
      final exists = box.containsKey(serverName);
      print('[FILE_TRACKER_SERVICE] Server exists in box: $exists');
      
      if (exists) {
        print('[FILE_TRACKER_SERVICE] Deleting server from box...');
        await box.delete(serverName);
        print('[FILE_TRACKER_SERVICE] Server deleted from box');
      } else {
        print('[FILE_TRACKER_SERVICE] Server does not exist in box, nothing to delete');
      }
      
      // Ensure deletion is persisted to disk
      print('[FILE_TRACKER_SERVICE] Flushing box to disk...');
      await box.flush();
      print('[FILE_TRACKER_SERVICE] Box flushed successfully');
      
      // Verify deletion
      final stillExists = box.containsKey(serverName);
      print('[FILE_TRACKER_SERVICE] Server still exists after delete: $stillExists');
      
      if (stillExists) {
        print('[FILE_TRACKER_SERVICE] WARNING: Server still exists after delete!');
      } else {
        print('[FILE_TRACKER_SERVICE] Delete verified: server no longer exists');
      }
    } catch (e, stackTrace) {
      print('[FILE_TRACKER_SERVICE] ERROR in deleteConfig: $e');
      print('[FILE_TRACKER_SERVICE] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Gets the currently active server name.
  ///
  /// Returns null if no server is set as active.
  Future<String?> getActiveServerName() async {
    final box = await _getActiveServerBox();
    return box.get('active_server');
  }

  /// Sets the currently active server name.
  /// Pass null to clear the active server.
  Future<void> setActiveServerName(String? serverName) async {
    final box = await _getActiveServerBox();
    if (serverName == null) {
      await box.delete('active_server');
    } else {
      await box.put('active_server', serverName);
    }
    // Ensure data is persisted to disk
    await box.flush();
  }

  /// Gets the currently active server configuration.
  ///
  /// Returns null if no active server is set or the config doesn't exist.
  /// Also handles migration of old data format.
  Future<FileServerConfig?> getActiveConfig() async {
    final box = await _getBox();
    
    // Check for old data format first
    if (box.containsKey('config')) {
      await _migrateOldConfig(box);
    }
    
    final activeName = await getActiveServerName();
    if (activeName == null) {
      // If no active server name, check if there's only one server
      final allConfigs = box.values.map((model) => model.toEntity()).toList();
      if (allConfigs.length == 1) {
        // Only one server, set it as active
        await setActiveServerName(allConfigs.first.serverName);
        return allConfigs.first;
      }
      return null;
    }
    return await getConfig(activeName);
  }
}

