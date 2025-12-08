import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/hive/hive_module_initializer.dart';
import '../data/models/file_server_config_model.dart';
import '../data/models/file_metadata_model.dart';
import 'constants.dart';

/// Hive initializer for the file_tracker module.
///
/// This class handles registration of all Hive adapters and opening of all
/// Hive boxes required by the file_tracker module. It implements the
/// HiveModuleInitializer interface so it can be discovered and called by
/// the central HiveInitializer.
class FileTrackerHiveInitializer implements HiveModuleInitializer {
  @override
  Future<void> registerAdapters() async {
    // Register FileServerConfigModel adapter (TypeId: 30)
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(FileServerConfigModelAdapter());
    }
    // Register FileMetadataModel adapter (TypeId: 31)
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(FileMetadataModelAdapter());
    }
  }

  @override
  Future<void> openBoxes() async {
    // Open file tracker config box
    try {
      await Hive.openBox<FileServerConfigModel>(fileTrackerConfigBoxName);
      // Open active server name box
      await Hive.openBox<String>('${fileTrackerConfigBoxName}_active');
    } catch (e) {
      // If adapter not registered, box cannot be opened
      // This will be resolved after running build_runner
    }
    // Open file tracker metadata box
    try {
      await Hive.openBox<FileMetadataModel>(fileTrackerMetadataBoxName);
    } catch (e) {
      // If adapter not registered, box cannot be opened
      // This will be resolved after running build_runner
    }
  }
}

