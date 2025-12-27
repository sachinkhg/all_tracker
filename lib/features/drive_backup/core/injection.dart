import '../../backup/data/datasources/google_auth_datasource.dart';
import '../../backup/data/datasources/drive_api_client.dart';
import '../data/datasources/drive_backup_config_datasource.dart';
import '../data/datasources/drive_folder_datasource.dart';
import '../data/datasources/google_sheets_crud_datasource.dart';
import '../data/services/drive_backup_service.dart';
import '../data/services/google_sheets_service.dart';
import '../data/repositories/drive_backup_repository_impl.dart';
import '../domain/usecases/setup_drive_backup.dart';
import '../domain/usecases/backup_to_drive.dart';
import '../domain/usecases/restore_from_drive.dart';
import '../presentation/cubit/drive_backup_cubit.dart';
import '../../../trackers/book_tracker/features/drive_backup_crud_logger.dart';

/// Create Drive backup repository with all dependencies.
DriveBackupRepositoryImpl createDriveBackupRepository() {
  // Data sources
  final googleAuth = GoogleAuthDataSource();
  final driveApiClient = DriveApiClient(googleAuth);
  final configDataSource = DriveBackupConfigDataSource();
  final folderDataSource = DriveFolderDataSource(driveApiClient);
  final sheetsService = GoogleSheetsService(googleAuth);
  final sheetsCrudDataSource = GoogleSheetsCrudDataSource(sheetsService);
  final backupService = DriveBackupService();
  final crudLogger = DriveBackupCrudLogger();

  // Repository
  return DriveBackupRepositoryImpl(
    configDataSource: configDataSource,
    folderDataSource: folderDataSource,
    sheetsCrudDataSource: sheetsCrudDataSource,
    backupService: backupService,
    sheetsService: sheetsService,
    crudLogger: crudLogger,
  );
}

/// Create Drive backup cubit with all dependencies.
DriveBackupCubit createDriveBackupCubit() {
  final repository = createDriveBackupRepository();

  // Use cases
  final setupBackup = SetupDriveBackup(repository);
  final backupToDrive = BackupToDrive(repository);
  final restoreFromDrive = RestoreFromDrive(repository);

  // Cubit
  return DriveBackupCubit(
    setupBackup: setupBackup,
    backupToDrive: backupToDrive,
    restoreFromDrive: restoreFromDrive,
  );
}

/// Get the CRUD logger instance.
/// 
/// This should be a singleton to maintain the operation queue.
DriveBackupCrudLogger? _crudLoggerInstance;

DriveBackupCrudLogger getDriveBackupCrudLogger() {
  _crudLoggerInstance ??= DriveBackupCrudLogger();
  return _crudLoggerInstance!;
}

