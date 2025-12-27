import '../../domain/entities/drive_backup_config.dart';
import '../../domain/repositories/drive_backup_repository.dart';
import '../datasources/drive_backup_config_datasource.dart';
import '../datasources/drive_folder_datasource.dart';
import '../datasources/google_sheets_crud_datasource.dart';
import '../services/drive_backup_service.dart';
import '../services/google_sheets_service.dart';
import '../../../../trackers/book_tracker/features/drive_backup_crud_logger.dart';

/// Implementation of DriveBackupRepository.
class DriveBackupRepositoryImpl implements DriveBackupRepository {
  final DriveBackupConfigDataSource _configDataSource;
  final DriveFolderDataSource _folderDataSource;
  final GoogleSheetsCrudDataSource _sheetsCrudDataSource;
  final DriveBackupService _backupService;
  final GoogleSheetsService _sheetsService;
  final DriveBackupCrudLogger _crudLogger;

  DriveBackupRepositoryImpl({
    required DriveBackupConfigDataSource configDataSource,
    required DriveFolderDataSource folderDataSource,
    required GoogleSheetsCrudDataSource sheetsCrudDataSource,
    required DriveBackupService backupService,
    required GoogleSheetsService sheetsService,
    required DriveBackupCrudLogger crudLogger,
  })  : _configDataSource = configDataSource,
        _folderDataSource = folderDataSource,
        _sheetsCrudDataSource = sheetsCrudDataSource,
        _backupService = backupService,
        _sheetsService = sheetsService,
        _crudLogger = crudLogger;

  @override
  Future<DriveBackupConfig?> getConfig() {
    return _configDataSource.getConfig();
  }

  @override
  Future<void> saveConfig(DriveBackupConfig config) {
    return _configDataSource.saveConfig(config);
  }

  @override
  Future<DriveBackupConfig> setupBackup(
    String rootFolderId,
    String trackerName,
  ) async {
    try {
      // Extract folder ID if it's a URL
      final folderId = _folderDataSource.extractFolderId(rootFolderId);
      print('[Drive Backup] Extracted folder ID: $folderId');

      // Create tracker-specific folder
      final trackerFolderName = trackerName;
      print('[Drive Backup] Creating folder: $trackerFolderName in folder: $folderId');
      final trackerFolderId = await _folderDataSource.createFolder(
        trackerFolderName,
        parentFolderId: folderId,
      );
      print('[Drive Backup] Created folder with ID: $trackerFolderId');

      // Create spreadsheet for book data directly in the tracker folder
      final spreadsheetTitle = '$trackerName - Data';
      print('[Drive Backup] Creating spreadsheet: $spreadsheetTitle in folder: $trackerFolderId');
      final spreadsheetId = await _sheetsService.createSpreadsheet(
        spreadsheetTitle,
        parentFolderId: trackerFolderId,
      );
      print('[Drive Backup] Created spreadsheet with ID: $spreadsheetId in folder');

      // Initialize sheet with headers
      print('[Drive Backup] Initializing sheet with headers');
      await _sheetsCrudDataSource.initializeSheet(spreadsheetId);
      print('[Drive Backup] Sheet initialized');

      // Save configuration
      final config = DriveBackupConfig(
        folderId: trackerFolderId,
        spreadsheetId: spreadsheetId,
      );
      await saveConfig(config);
      print('[Drive Backup] Configuration saved');

      return config;
    } catch (e, stackTrace) {
      print('[Drive Backup] Error in setupBackup: $e');
      print('[Drive Backup] Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> backupToDrive() async {
    final config = await getConfig();
    if (config == null) {
      throw Exception('Drive backup not configured. Please setup backup first.');
    }

    try {
      // Get all books from Hive
      print('[Drive Backup] Getting all books from Hive');
      final booksBox = await _backupService.getAllBooks();
      print('[Drive Backup] Found ${booksBox.length} books');
      
      // Write all books to Google Sheet (current state approach - Option A)
      print('[Drive Backup] Writing ${booksBox.length} books to Google Sheet: ${config.spreadsheetId}');
      await _sheetsCrudDataSource.writeAllBooks(config.spreadsheetId, booksBox);
      print('[Drive Backup] Successfully wrote books to Google Sheet');

      // Also create JSON backup as fallback
      print('[Drive Backup] Creating JSON backup file');
      final jsonData = await _backupService.serializeBooksToJson();
      const fileName = 'books_backup.json';
      await _folderDataSource.uploadJsonFile(fileName, jsonData, config.folderId);
      print('[Drive Backup] JSON backup file created');

      // Note: CRUD operations are logged but not synced to sheet in Option A approach
      // The sheet contains only the current state of all books
      // User can edit the sheet directly, and restore will read from it

      // Get the actual modified time of the spreadsheet from Drive API
      final sheetMetadata = await _folderDataSource.getFileMetadata(config.spreadsheetId);
      final sheetModifiedTimeStr = sheetMetadata['modifiedTime'] as String?;
      DateTime? sheetModifiedTime;
      if (sheetModifiedTimeStr != null) {
        try {
          sheetModifiedTime = DateTime.parse(sheetModifiedTimeStr);
        } catch (e) {
          // Ignore parse errors
        }
      }

      // Update last backup time and sheet sync time
      final updatedConfig = config.copyWith(
        lastBackupTime: DateTime.now(),
        lastSheetSyncTime: sheetModifiedTime ?? DateTime.now(),
      );
      await saveConfig(updatedConfig);
      print('[Drive Backup] Backup completed successfully');
    } catch (e, stackTrace) {
      print('[Drive Backup] Error in backupToDrive: $e');
      print('[Drive Backup] Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> restoreFromDrive() async {
    final config = await getConfig();
    if (config == null) {
      throw Exception('Drive backup not configured. Please setup backup first.');
    }

    // Check which source is newer: JSON file or Google Sheet
    const jsonFileName = 'books_backup.json';
    final jsonFileId = await _folderDataSource.findFile(jsonFileName, config.folderId);

    DateTime? jsonModifiedTime;
    if (jsonFileId != null) {
      final jsonMetadata = await _folderDataSource.getFileMetadata(jsonFileId);
      final modifiedTimeStr = jsonMetadata['modifiedTime'] as String?;
      if (modifiedTimeStr != null) {
        try {
          jsonModifiedTime = DateTime.parse(modifiedTimeStr);
        } catch (e) {
          // Ignore parse errors
        }
      }
    }

    // Get the actual modified time of the spreadsheet from Drive API
    DateTime? sheetModifiedTime;
    try {
      final sheetMetadata = await _folderDataSource.getFileMetadata(config.spreadsheetId);
      final sheetModifiedTimeStr = sheetMetadata['modifiedTime'] as String?;
      if (sheetModifiedTimeStr != null) {
        try {
          sheetModifiedTime = DateTime.parse(sheetModifiedTimeStr);
        } catch (e) {
          // Ignore parse errors
        }
      }
    } catch (e) {
      print('[Drive Backup] Could not get sheet metadata: $e');
    }

    // Determine which source to use (prefer sheet if newer, otherwise JSON)
    bool useSheet = false;
    if (sheetModifiedTime != null && jsonModifiedTime != null) {
      useSheet = sheetModifiedTime.isAfter(jsonModifiedTime);
      print('[Drive Backup] Sheet modified: $sheetModifiedTime, JSON modified: $jsonModifiedTime');
      print('[Drive Backup] Using ${useSheet ? "Google Sheet" : "JSON file"} (newer source)');
    } else if (sheetModifiedTime != null) {
      useSheet = true;
      print('[Drive Backup] Using Google Sheet (JSON file not found)');
    } else if (jsonModifiedTime != null) {
      useSheet = false;
      print('[Drive Backup] Using JSON file (sheet metadata not available)');
    } else {
      throw Exception('No backup data found in Drive');
    }

    if (useSheet) {
      // Restore from Google Sheet
      final booksList = await _sheetsCrudDataSource.readBooksFromSheet(config.spreadsheetId);
      // Restore books to Hive
      await _backupService.restoreBooksToHive(booksList);
    } else {
      // Restore from JSON file
      if (jsonFileId == null) {
        throw Exception('Backup JSON file not found in Drive');
      }
      final jsonData = await _folderDataSource.downloadJsonFile(jsonFileId);
      final booksList = _backupService.deserializeBooksFromJson(jsonData);
      // Restore books to Hive
      await _backupService.restoreBooksToHive(booksList);
    }

    // Update last restore time
    final updatedConfig = config.copyWith(
      lastRestoreTime: DateTime.now(),
    );
    await saveConfig(updatedConfig);
  }

  @override
  Future<void> syncCrudToSheet() async {
    final config = await getConfig();
    if (config == null) {
      throw Exception('Drive backup not configured. Please setup backup first.');
    }

    // Get queued CRUD operations
    final operations = _crudLogger.getQueuedOperations();

    if (operations.isEmpty) {
      return;
    }

    // Append operations to sheet
    await _sheetsCrudDataSource.appendOperations(config.spreadsheetId, operations);

    // Clear the queue
    _crudLogger.clearQueue();

    // Update last sync time
    final updatedConfig = config.copyWith(
      lastSheetSyncTime: DateTime.now(),
    );
    await saveConfig(updatedConfig);
  }
}

