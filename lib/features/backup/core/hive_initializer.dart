import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/hive/hive_module_initializer.dart';
import 'package:all_tracker/trackers/goal_tracker/core/constants.dart';
import '../data/models/backup_metadata_model.dart';

/// Hive initializer for the backup feature.
class BackupHiveInitializer implements HiveModuleInitializer {
  @override
  Future<void> registerAdapters() async {
    // Register BackupMetadataModel adapter (TypeId: 5)
    final backupMetadataAdapterId = BackupMetadataModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(backupMetadataAdapterId)) {
      Hive.registerAdapter(BackupMetadataModelAdapter());
    }
  }

  @override
  Future<void> openBoxes() async {
    // Open backup boxes
    await Hive.openBox<BackupMetadataModel>(backupMetadataBoxName);
    await Hive.openBox(backupPreferencesBoxName);
  }
}

