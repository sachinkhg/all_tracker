// lib/features/backup/core/injection.dart
// Composition root for backup feature: wires data -> repository -> usecases -> cubit.

import 'package:hive_flutter/hive_flutter.dart';

import '../../../../trackers/goal_tracker/core/constants.dart';
import '../core/encryption_service.dart';
import '../core/device_info_service.dart';
import '../core/backup_preferences_service.dart';
import '../core/backup_scheduler_service.dart';
import '../data/datasources/google_auth_datasource.dart';
import '../data/datasources/drive_api_client.dart';
import '../data/datasources/backup_metadata_local_datasource.dart';
import '../data/services/backup_builder_service.dart';
import '../data/repositories/backup_repository_impl.dart';
import '../data/models/backup_metadata_model.dart';
import '../domain/usecases/create_backup.dart';
import '../domain/usecases/list_backups.dart';
import '../domain/usecases/restore_backup.dart';
import '../domain/usecases/delete_backup.dart';
import '../presentation/cubit/backup_cubit.dart';

/// ---------------------------------------------------------------------------
/// Backup Feature Dependency Injection
/// ---------------------------------------------------------------------------
/// 
/// Purpose:
/// - Provides factory functions for creating backup-related dependencies
/// - Wires up the complete backup feature dependency graph
/// - Ensures proper initialization order and dependency resolution
///
/// Notes:
/// - Assumes the Hive backup metadata box has already been opened.
/// - Wires up the complete backup feature dependency graph:
///   Data sources → Services → Repository → Use cases
/// - The BackupCubit (presentation layer) can be created separately
///   once it's implemented.
/// ---------------------------------------------------------------------------

/// Create the backup repository with all dependencies.
BackupRepositoryImpl createBackupRepository() {
  // Ensure Hive.box<BackupMetadataModel>(backupMetadataBoxName) is opened beforehand
  final Box<BackupMetadataModel> backupBox = Hive.box<BackupMetadataModel>(backupMetadataBoxName);

  // ---------------------------------------------------------------------------
  // Data sources
  // ---------------------------------------------------------------------------
  final googleAuth = GoogleAuthDataSource();
  final driveApi = DriveApiClient(googleAuth);
  final encryptionService = EncryptionService();
  final deviceInfoService = DeviceInfoService();
  final backupMetadataLocal = BackupMetadataLocalDataSourceImpl(backupBox);

  // ---------------------------------------------------------------------------
  // Services
  // ---------------------------------------------------------------------------
  final backupBuilder = BackupBuilderService();

  // ---------------------------------------------------------------------------
  // Repository
  // ---------------------------------------------------------------------------
  return BackupRepositoryImpl(
    googleAuth: googleAuth,
    driveApi: driveApi,
    encryptionService: encryptionService,
    backupBuilder: backupBuilder,
    metadataDataSource: backupMetadataLocal,
    deviceInfoService: deviceInfoService,
  );
}

/// Create all backup use cases.
///
/// Returns a map of use cases keyed by name for easy access.
Map<String, dynamic> createBackupUseCases() {
  final repository = createBackupRepository();

  return {
    'createBackup': CreateBackup(repository),
    'listBackups': ListBackups(repository),
    'restoreBackup': RestoreBackup(repository),
    'deleteBackup': DeleteBackup(repository),
    'repository': repository, // Also provide repository for progress stream access
  };
}

/// Create a fully-wired BackupCubit instance.
///
/// This factory function wires up all dependencies for the backup feature:
/// - Services (encryption, device info, preferences)
/// - Data sources (Google Auth, Drive API, local metadata storage)
/// - Repository (orchestrates backup operations)
/// - Use cases (single-responsibility operations)
/// - Cubit (state management)
BackupCubit createBackupCubit() {
  // Services
  final encryptionService = EncryptionService();
  final deviceInfoService = DeviceInfoService();
  final backupPrefsService = BackupPreferencesService();
  
  // Data sources
  final googleAuth = GoogleAuthDataSource();
  final driveApi = DriveApiClient(googleAuth);
  
  final backupBox = Hive.box<BackupMetadataModel>(backupMetadataBoxName);
  final metadataDataSource = BackupMetadataLocalDataSourceImpl(backupBox);
  
  // Backup builder service
  final backupBuilder = BackupBuilderService();
  
  // Repository
  final repository = BackupRepositoryImpl(
    googleAuth: googleAuth,
    driveApi: driveApi,
    encryptionService: encryptionService,
    backupBuilder: backupBuilder,
    metadataDataSource: metadataDataSource,
    deviceInfoService: deviceInfoService,
  );
  
  // Use cases
  final createBackup = CreateBackup(repository);
  final listBackups = ListBackups(repository);
  final restoreBackup = RestoreBackup(repository);
  final deleteBackup = DeleteBackup(repository);
  
  // Cubit
  return BackupCubit(
    createBackup: createBackup,
    listBackups: listBackups,
    restoreBackup: restoreBackup,
    deleteBackup: deleteBackup,
    preferencesService: backupPrefsService,
    googleAuth: googleAuth,
  );
}

/// Create a BackupSchedulerService instance for automatic backups.
///
/// This service checks if automatic backups should run and executes them
/// when enabled and the 24-hour interval has passed.
BackupSchedulerService createBackupSchedulerService() {
  final backupPrefsService = BackupPreferencesService();
  
  // Create repository and use case for backup creation
  final encryptionService = EncryptionService();
  final deviceInfoService = DeviceInfoService();
  final googleAuth = GoogleAuthDataSource();
  final driveApi = DriveApiClient(googleAuth);
  final backupBox = Hive.box<BackupMetadataModel>(backupMetadataBoxName);
  final metadataDataSource = BackupMetadataLocalDataSourceImpl(backupBox);
  final backupBuilder = BackupBuilderService();
  
  final repository = BackupRepositoryImpl(
    googleAuth: googleAuth,
    driveApi: driveApi,
    encryptionService: encryptionService,
    backupBuilder: backupBuilder,
    metadataDataSource: metadataDataSource,
    deviceInfoService: deviceInfoService,
  );
  
  final createBackup = CreateBackup(repository);
  
  return BackupSchedulerService(
    preferencesService: backupPrefsService,
    createBackupUseCase: createBackup,
    googleAuth: googleAuth,
  );
}

