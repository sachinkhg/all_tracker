import '../../domain/entities/drive_backup_config.dart';
import '../../domain/repositories/drive_backup_repository.dart';
import '../datasources/drive_backup_config_datasource.dart';
import '../datasources/drive_folder_datasource.dart';
import '../datasources/google_sheets_crud_datasource.dart';
import '../services/drive_backup_service.dart';
import '../services/google_sheets_service.dart';
import '../../../../trackers/book_tracker/features/drive_backup_crud_logger.dart';
import '../../../../trackers/book_tracker/domain/repositories/book_repository.dart';
import '../../../../trackers/book_tracker/domain/entities/book.dart';
import '../../../../trackers/book_tracker/domain/entities/read_history_entry.dart';
import 'package:uuid/uuid.dart';

/// Implementation of DriveBackupRepository.
class DriveBackupRepositoryImpl implements DriveBackupRepository {
  final DriveBackupConfigDataSource _configDataSource;
  final DriveFolderDataSource _folderDataSource;
  final GoogleSheetsCrudDataSource _sheetsCrudDataSource;
  final DriveBackupService _backupService;
  final GoogleSheetsService _sheetsService;
  final DriveBackupCrudLogger _crudLogger;
  final BookRepository _bookRepository;
  final Uuid _uuid = const Uuid();

  DriveBackupRepositoryImpl({
    required DriveBackupConfigDataSource configDataSource,
    required DriveFolderDataSource folderDataSource,
    required GoogleSheetsCrudDataSource sheetsCrudDataSource,
    required DriveBackupService backupService,
    required GoogleSheetsService sheetsService,
    required DriveBackupCrudLogger crudLogger,
    required BookRepository bookRepository,
  })  : _configDataSource = configDataSource,
        _folderDataSource = folderDataSource,
        _sheetsCrudDataSource = sheetsCrudDataSource,
        _backupService = backupService,
        _sheetsService = sheetsService,
        _crudLogger = crudLogger,
        _bookRepository = bookRepository;

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

      // Create tracker-specific folder
      final trackerFolderName = trackerName;
      final trackerFolderId = await _folderDataSource.createFolder(
        trackerFolderName,
        parentFolderId: folderId,
      );

      // Create spreadsheet for book data directly in the tracker folder
      final spreadsheetTitle = '$trackerName - Data';
      final spreadsheetId = await _sheetsService.createSpreadsheet(
        spreadsheetTitle,
        parentFolderId: trackerFolderId,
      );

      // Initialize sheet with headers
      await _sheetsCrudDataSource.initializeSheet(spreadsheetId);

      // Save configuration
      final config = DriveBackupConfig(
        folderId: trackerFolderId,
        spreadsheetId: spreadsheetId,
      );
      await saveConfig(config);

      return config;
    } catch (e) {
      print('[Drive Backup] Error in setupBackup: $e');
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
      final booksBox = await _backupService.getAllBooks();
      
      // Write all books to Google Sheet (current state approach - Option A)
      await _sheetsCrudDataSource.writeAllBooks(config.spreadsheetId, booksBox);

      // Also create JSON backup as fallback
      final jsonData = await _backupService.serializeBooksToJson();
      const fileName = 'books_backup.json';
      await _folderDataSource.uploadJsonFile(fileName, jsonData, config.folderId);

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
    } catch (e) {
      print('[Drive Backup] Error in backupToDrive: $e');
      rethrow;
    }
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

  @override
  Future<void> syncActionsFromSheet() async {
    final config = await getConfig();
    if (config == null) {
      throw Exception('Drive backup not configured. Please setup backup first.');
    }

    final booksWithActions = await _sheetsCrudDataSource.readBooksWithActions(config.spreadsheetId);
    
    if (booksWithActions.isEmpty) {
      return;
    }

    // Process each action
    final rowsToClear = <int>[];
    final rowsToDelete = <int>[]; // Rows to delete from sheet (1-based, including header offset)
    final rowsToUpdate = <({int rowNumber, Book updatedBook, String action})>[]; // Rows to update in sheet
    
    for (final entry in booksWithActions.entries) {
      final rowIndex = entry.key; // 0-based (first data row is 0)
      final book = entry.value.book;
      final action = entry.value.action;
      final originalBookId = entry.value.originalBookId;
      final sheetRowNumber = rowIndex + 2; // Convert to 1-based sheet row (row 1 is header)

      try {
        if (action == 'CREATE BOOK') {
          final updatedBook = await _handleCreateBookAction(book, originalBookId);
          rowsToUpdate.add((rowNumber: sheetRowNumber, updatedBook: updatedBook, action: action));
          rowsToClear.add(rowIndex);
        } else if (action == 'UPDATE BOOK') {
          final updatedBook = await _handleUpdateBookAction(book);
          rowsToUpdate.add((rowNumber: sheetRowNumber, updatedBook: updatedBook, action: action));
          rowsToClear.add(rowIndex);
        } else if (action == 'DELETE BOOK') {
          // Find all rows with this book ID before deleting (to avoid row number shifts)
          final rowsToDeleteForBook = await _findRowsForBookId(config.spreadsheetId, originalBookId);
          rowsToDelete.addAll(rowsToDeleteForBook);
          // Delete the book from the database
          await _handleDeleteBookAction(book.id, config.spreadsheetId);
          // Don't add to rowsToClear since we're deleting the rows
        } else if (action == 'CREATE REREAD') {
          final updatedBook = await _handleCreateRereadAction(book, originalBookId);
          rowsToUpdate.add((rowNumber: sheetRowNumber, updatedBook: updatedBook, action: action));
          rowsToClear.add(rowIndex);
        } else if (action == 'UPDATE REREAD') {
          final updatedBook = await _handleUpdateRereadAction(book, originalBookId);
          rowsToUpdate.add((rowNumber: sheetRowNumber, updatedBook: updatedBook, action: action));
          rowsToClear.add(rowIndex);
        } else if (action == 'DELETE REREAD') {
          await _handleDeleteRereadAction(book, originalBookId);
          rowsToDelete.add(sheetRowNumber); // Delete this specific row
          // Don't add to rowsToClear since we're deleting the row
        }
      } catch (e) {
        print('[Drive Backup] Error processing $action action for book ${book.id}: $e');
        // Continue processing other actions even if one fails
      }
    }

    // Update rows in sheet FIRST (before deleting to avoid row number shifts)
    // Process in batches of 50 rows at once to avoid quota issues
    if (rowsToUpdate.isNotEmpty) {
      // Sort by row number descending
      rowsToUpdate.sort((a, b) => b.rowNumber.compareTo(a.rowNumber));
      
      // Read all rows once at the beginning to avoid multiple reads
      final allRows = await _sheetsService.readAllRows(config.spreadsheetId);
      
      // Process in batches of 50 rows with 2-second delay between batches
      const batchSize = 50;
      const delayBetweenBatches = Duration(seconds: 2);
      const maxRetriesPerBatch = 5;
      
      // Track failed batches for retry
      final failedBatches = <List<({int rowNumber, Book updatedBook, String action})>>[];
      
      for (int i = 0; i < rowsToUpdate.length; i += batchSize) {
        final batch = rowsToUpdate.skip(i).take(batchSize).toList();
        
        bool batchSuccess = false;
        int retryAttempt = 0;
        
        while (!batchSuccess && retryAttempt <= maxRetriesPerBatch) {
          try {
            // Prepare batch update data
            final batchUpdates = <String, List<List<Object?>>>{};
            
            for (final updateInfo in batch) {
              final rowNumber = updateInfo.rowNumber;
              
              // Validate row exists
              if (allRows.length < rowNumber) {
                continue;
              }
              
              final existingRow = allRows[rowNumber - 1]; // Convert to 0-based index
              if (existingRow.isEmpty || existingRow.length < 11) {
                continue;
              }
              
              if (updateInfo.action == 'CREATE BOOK') {
                // CREATE BOOK: Update Book ID, Created At, Updated At (columns A, I, J)
                final range = 'Sheet1!A$rowNumber:J$rowNumber';
                batchUpdates[range] = [[
                  updateInfo.updatedBook.id,
                  existingRow[1], // Title (preserve)
                  existingRow[2], // Author (preserve)
                  existingRow[3], // Page Count (preserve)
                  existingRow[4], // Self Rating (preserve)
                  existingRow[5], // Published Date (preserve)
                  existingRow[6], // Date Started (preserve)
                  existingRow[7], // Date Read (preserve)
                  updateInfo.updatedBook.createdAt.toIso8601String(), // Created At
                  updateInfo.updatedBook.updatedAt.toIso8601String(), // Updated At
                ]];
              } else {
                // UPDATE BOOK, CREATE REREAD, UPDATE REREAD: Update Updated At only (column J)
                final range = 'Sheet1!J$rowNumber';
                batchUpdates[range] = [[
                  updateInfo.updatedBook.updatedAt.toIso8601String(),
                ]];
              }
            }
            
            if (batchUpdates.isNotEmpty) {
              await _sheetsService.batchUpdateCells(
                config.spreadsheetId,
                batchUpdates,
                maxRetries: 3, // Service-level retries
              );
              batchSuccess = true;
            } else {
              // No valid updates in batch, mark as success
              batchSuccess = true;
            }
          } catch (e) {
            final errorStr = e.toString();
            final isQuotaError = errorStr.contains('429') || 
                                errorStr.contains('Quota exceeded') ||
                                errorStr.contains('rateLimitExceeded');
            
            if (isQuotaError && retryAttempt < maxRetriesPerBatch) {
              retryAttempt++;
              // Fixed delays: 5, 10, 20, 30, 45 seconds
              final delaySeconds = _getRetryDelay(retryAttempt);
              await Future.delayed(Duration(seconds: delaySeconds));
              continue;
            }
            
            // Non-quota error or max retries reached
            if (isQuotaError) {
              // Add to failed batches for later retry
              failedBatches.add(batch);
            }
            break; // Exit retry loop
          }
        }
        
        // Add delay between batches to avoid quota errors (except for last batch)
        if (i + batchSize < rowsToUpdate.length && batchSuccess) {
          await Future.delayed(delayBetweenBatches);
        }
      }
      
      // Retry failed batches with longer delays
      if (failedBatches.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 5)); // Wait longer before retrying failed batches
        
        for (int retryIndex = 0; retryIndex < failedBatches.length; retryIndex++) {
          final batch = failedBatches[retryIndex];
          
          bool retrySuccess = false;
          int retryAttempt = 0;
          const maxRetriesForFailed = 3;
          
          while (!retrySuccess && retryAttempt < maxRetriesForFailed) {
            try {
              final batchUpdates = <String, List<List<Object?>>>{};
              
              for (final updateInfo in batch) {
                final rowNumber = updateInfo.rowNumber;
                
                if (allRows.length < rowNumber) continue;
                final existingRow = allRows[rowNumber - 1];
                if (existingRow.isEmpty || existingRow.length < 11) continue;
                
                if (updateInfo.action == 'CREATE BOOK') {
                  final range = 'Sheet1!A$rowNumber:J$rowNumber';
                  batchUpdates[range] = [[
                    updateInfo.updatedBook.id,
                    existingRow[1], existingRow[2], existingRow[3], existingRow[4],
                    existingRow[5], existingRow[6], existingRow[7],
                    updateInfo.updatedBook.createdAt.toIso8601String(),
                    updateInfo.updatedBook.updatedAt.toIso8601String(),
                  ]];
                } else {
                  final range = 'Sheet1!J$rowNumber';
                  batchUpdates[range] = [[
                    updateInfo.updatedBook.updatedAt.toIso8601String(),
                  ]];
                }
              }
              
              if (batchUpdates.isNotEmpty) {
                await _sheetsService.batchUpdateCells(
                  config.spreadsheetId,
                  batchUpdates,
                  maxRetries: 3,
                );
                retrySuccess = true;
              } else {
                retrySuccess = true;
              }
            } catch (e) {
              retryAttempt++;
              final errorStr = e.toString();
              final isQuotaError = errorStr.contains('429') || 
                                  errorStr.contains('Quota exceeded') ||
                                  errorStr.contains('rateLimitExceeded');
              
              if (isQuotaError && retryAttempt < maxRetriesForFailed) {
                final delaySeconds = _getRetryDelay(retryAttempt);
                await Future.delayed(Duration(seconds: delaySeconds));
              } else {
                break;
              }
            }
          }
          
          // Delay between retrying failed batches
          if (retryIndex < failedBatches.length - 1) {
            await Future.delayed(const Duration(seconds: 3));
          }
        }
      }
      
    }

    // Delete rows from sheet (after updates to avoid row number shifts)
    if (rowsToDelete.isNotEmpty) {
      // Remove duplicates and sort descending
      final uniqueRowsToDelete = rowsToDelete.toSet().toList()..sort((a, b) => b.compareTo(a));
      await _sheetsService.deleteRows(config.spreadsheetId, uniqueRowsToDelete);
    }

    // Clear action column for processed rows (only for non-delete actions)
    // Note: We update BEFORE deleting, so row numbers are still correct here
    if (rowsToClear.isNotEmpty) {
      await _clearActionColumn(config.spreadsheetId, rowsToClear);
    }

    // Update last sync time
    final updatedConfig = config.copyWith(
      lastSheetSyncTime: DateTime.now(),
    );
    await saveConfig(updatedConfig);

    print('[Drive Backup] Successfully synced actions from sheet');
  }

  /// Get retry delay in seconds based on retry attempt number.
  /// Returns: 5, 10, 20, 30, 45 seconds for attempts 1-5 respectively.
  int _getRetryDelay(int retryAttempt) {
    switch (retryAttempt) {
      case 1:
        return 5;
      case 2:
        return 10;
      case 3:
        return 20;
      case 4:
        return 30;
      case 5:
        return 45;
      default:
        return 45; // Default to max delay for attempts beyond 5
    }
  }

  /// Handle CREATE BOOK action: create a new book with its first read.
  /// 
  /// [book]: The book data from the sheet
  /// [originalBookId]: The original bookId from the sheet (may be empty for new books)
  /// Returns the created book.
  Future<Book> _handleCreateBookAction(Book book, String originalBookId) async {
    final bookId = originalBookId.trim();
    final finalBookId = bookId.isEmpty ? _uuid.v4() : bookId;
    
    final newBook = book.copyWith(
      id: finalBookId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _bookRepository.createBook(newBook);
    _crudLogger.logCreate(newBook);
    return newBook;
  }

  /// Handle UPDATE BOOK action: update existing book metadata.
  /// Returns the updated book.
  Future<Book> _handleUpdateBookAction(Book book) async {
    final updatedBook = book.copyWith(
      updatedAt: DateTime.now(),
    );
    await _bookRepository.updateBook(updatedBook);
    _crudLogger.logUpdate(updatedBook);
    return updatedBook;
  }

  /// Handle DELETE BOOK action: delete book and all its read history.
  /// 
  /// Also deletes all rows from the Google Sheet with this book ID.
  /// [bookId]: The ID of the book to delete
  /// [spreadsheetId]: The spreadsheet ID (for sheet cleanup)
  Future<void> _handleDeleteBookAction(String bookId, String spreadsheetId) async {
    await _bookRepository.deleteBook(bookId);
    _crudLogger.logDelete(bookId);
    // Note: Rows will be deleted in the caller after this completes
  }

  /// Find all row numbers (1-based) in the sheet that have the given book ID.
  /// 
  /// Returns a list of row numbers (1-based) where the Book ID matches.
  Future<List<int>> _findRowsForBookId(String spreadsheetId, String bookId) async {
    final rows = await _sheetsService.readAllRows(spreadsheetId);
    if (rows.isEmpty) return [];

    final matchingRows = <int>[];
    
    // Skip header row (row 1), start from row 2 (index 1)
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isNotEmpty && row[0]?.toString().trim() == bookId.trim()) {
        final sheetRowNumber = i + 1; // Convert to 1-based
        matchingRows.add(sheetRowNumber);
      }
    }
    
    return matchingRows;
  }

  /// Handle CREATE REREAD action: add a new read history entry to an existing book.
  /// 
  /// [book]: The book data from the sheet (contains the read dates)
  /// [originalBookId]: The bookId from the sheet
  /// Returns the updated book.
  Future<Book> _handleCreateRereadAction(Book book, String originalBookId) async {
    final bookId = originalBookId.trim();
    if (bookId.isEmpty) {
      throw Exception('CREATE REREAD requires an existing book ID');
    }
    
    final existingBook = await _bookRepository.getBookById(bookId);
    if (existingBook == null) {
      throw Exception('Book not found: $bookId');
    }
    
    final newHistoryEntry = ReadHistoryEntry(
      dateStarted: book.dateStarted,
      dateRead: book.dateRead,
    );
    final updatedHistory = List<ReadHistoryEntry>.from(existingBook.readHistory)
      ..add(newHistoryEntry);
    
    final updatedBook = existingBook.copyWith(
      readHistory: updatedHistory,
      updatedAt: DateTime.now(),
    );
    await _bookRepository.updateBook(updatedBook);
    _crudLogger.logUpdate(updatedBook);
    return updatedBook;
  }

  /// Handle UPDATE REREAD action: update an existing read history entry.
  /// 
  /// Note: This matches read entries by dateStarted and dateRead from the row.
  /// Since read entries don't have unique IDs, matching is done by dates.
  /// If multiple entries have the same dates, the first match will be updated.
  /// 
  /// [book]: The book data from the sheet (contains the read dates to update)
  /// [originalBookId]: The bookId from the sheet
  /// Returns the updated book.
  Future<Book> _handleUpdateRereadAction(Book book, String originalBookId) async {
    final bookId = originalBookId.trim();
    if (bookId.isEmpty) {
      throw Exception('UPDATE REREAD requires a book ID');
    }
    
    final existingBook = await _bookRepository.getBookById(bookId);
    if (existingBook == null) {
      throw Exception('Book not found: $bookId');
    }
    
    final newDateStarted = book.dateStarted;
    final newDateRead = book.dateRead;
    
    // For UPDATE REREAD, we need to match an existing read entry
    // The dates in the row represent what we want to update TO
    // We match by the dates that are currently in the database
    // 
    // Note: This works best when the row already existed with dates, and the user
    // edited those dates in place. We match by dateStarted since it's the primary identifier.
    
    if (newDateStarted == null) {
      throw Exception('UPDATE REREAD requires dateStarted');
    }
    
    // First, check if we're updating the current read
    // Match by dateStarted
    if (existingBook.dateStarted != null) {
      final currentDateStarted = existingBook.dateStarted!;
      // Use a tolerance for date comparison (same day is close enough)
      final currentDateOnly = DateTime(
        currentDateStarted.year,
        currentDateStarted.month,
        currentDateStarted.day,
      );
      final newDateOnly = DateTime(
        newDateStarted.year,
        newDateStarted.month,
        newDateStarted.day,
      );
      
      // Check if dates are on the same day (allowing for time differences)
      if (currentDateOnly.isAtSameMomentAs(newDateOnly)) {
        // This is updating the current read
        final updatedBook = existingBook.copyWith(
          dateStarted: newDateStarted,
          dateRead: newDateRead,
          updatedAt: DateTime.now(),
        );
        await _bookRepository.updateBook(updatedBook);
        _crudLogger.logUpdate(updatedBook);
        return updatedBook;
      }
    }
    
    // Update a read history entry
    // Match by dateStarted (same day)
    final updatedHistory = <ReadHistoryEntry>[];
    bool found = false;
    
    for (final entry in existingBook.readHistory) {
      if (entry.dateStarted != null && !found) {
        final entryDateOnly = DateTime(
          entry.dateStarted!.year,
          entry.dateStarted!.month,
          entry.dateStarted!.day,
        );
        final newDateOnly = DateTime(
          newDateStarted.year,
          newDateStarted.month,
          newDateStarted.day,
        );
        
        // Match by same day
        if (entryDateOnly.isAtSameMomentAs(newDateOnly)) {
          // Update this entry with new dates
          updatedHistory.add(ReadHistoryEntry(
            dateStarted: newDateStarted,
            dateRead: newDateRead,
          ));
          found = true;
        } else {
          updatedHistory.add(entry);
        }
      } else {
        updatedHistory.add(entry);
      }
    }
    
    if (!found) {
      throw Exception('Read history entry not found for book: $bookId. '
          'Make sure the row\'s dateStarted matches an existing read entry.');
    }
    
    final updatedBook = existingBook.copyWith(
      readHistory: updatedHistory,
      updatedAt: DateTime.now(),
    );
    await _bookRepository.updateBook(updatedBook);
    _crudLogger.logUpdate(updatedBook);
    return updatedBook;
  }

  /// Handle DELETE REREAD action: delete a specific read history entry.
  /// 
  /// Matches the read history entry by dateStarted and dateRead from the row,
  /// and removes it from the book's readHistory.
  /// [book]: The book data from the sheet (contains the read dates to delete)
  /// [originalBookId]: The bookId from the sheet
  Future<void> _handleDeleteRereadAction(Book book, String originalBookId) async {
    final bookId = originalBookId.trim();
    if (bookId.isEmpty) {
      throw Exception('DELETE REREAD requires a book ID');
    }
    
    final existingBook = await _bookRepository.getBookById(bookId);
    if (existingBook == null) {
      throw Exception('Book not found: $bookId');
    }
    
    final targetDateStarted = book.dateStarted;
    final targetDateRead = book.dateRead;
    
    if (targetDateStarted == null) {
      throw Exception('DELETE REREAD requires dateStarted');
    }
    
    // Helper function to compare dates by day (ignoring time)
    bool datesMatchByDay(DateTime? date1, DateTime? date2) {
      if (date1 == null && date2 == null) return true;
      if (date1 == null || date2 == null) return false;
      return date1.year == date2.year &&
          date1.month == date2.month &&
          date1.day == date2.day;
    }
    
    // Check if it's the current read
    final matchesCurrentRead = existingBook.dateStarted != null &&
        datesMatchByDay(existingBook.dateStarted, targetDateStarted);
    
    if (matchesCurrentRead) {
      // Clear the current read (set dates to null)
      final updatedBook = existingBook.copyWith(
        dateStarted: null,
        dateRead: null,
        updatedAt: DateTime.now(),
      );
      await _bookRepository.updateBook(updatedBook);
      _crudLogger.logUpdate(updatedBook);
      return;
    }
    
    // Remove from readHistory
    final updatedHistory = existingBook.readHistory.where((entry) {
      // Match primarily by dateStarted (must match)
      final matchesDateStarted = datesMatchByDay(entry.dateStarted, targetDateStarted);
      
      if (!matchesDateStarted) {
        // dateStarted doesn't match, keep this entry
        return true;
      }
      
      // dateStarted matches - this is the primary identifier
      // For DELETE, we'll be lenient: if dateStarted matches, delete it
      // (dateRead might differ due to editing or being null)
      // However, if both have dateRead and they don't match, it might be a different read
      // So we check: if both have dateRead, they should match; otherwise, dateStarted match is enough
      final bothHaveDateRead = entry.dateRead != null && targetDateRead != null;
      final bothNullDateRead = entry.dateRead == null && targetDateRead == null;
      final matchesDateRead = bothNullDateRead ||
          (bothHaveDateRead && datesMatchByDay(entry.dateRead, targetDateRead)) ||
          (!bothHaveDateRead); // If only one has dateRead, still match (lenient)
      
      // Delete if dateStarted matches AND (dateRead matches or one is null)
      final shouldDelete = matchesDateStarted && matchesDateRead;
      
      // Keep entries that should NOT be deleted
      return !shouldDelete;
    }).toList();
    
    if (updatedHistory.length == existingBook.readHistory.length) {
      throw Exception('Read history entry not found for book: $bookId. '
          'Make sure the row\'s dateStarted and dateRead match an existing read entry.');
    }
    
    final updatedBook = existingBook.copyWith(
      readHistory: updatedHistory,
      updatedAt: DateTime.now(),
    );
    await _bookRepository.updateBook(updatedBook);
    _crudLogger.logUpdate(updatedBook);
  }

  /// Clear action column for specified rows using batch updates.
  /// 
  /// Uses batch updates to minimize API calls and handle quota errors with retry logic.
  Future<void> _clearActionColumn(String spreadsheetId, List<int> rowIndices) async {
    // Row indices are 0-based (first data row is 0, which is row 2 in the sheet)
    // Action column is column K (index 10), which is column 11 (1-based)
    // Sheet row numbers are 1-based, so row index 0 = sheet row 2
    
    if (rowIndices.isEmpty) {
      return;
    }
    
    // Group rows into batches for batch updates
    // Google Sheets batch update can handle up to 100 ranges per request
    const maxRangesPerBatch = 100;
    
    // Convert row indices to sheet row numbers and create ranges
    final rowNumbers = rowIndices.map((idx) => idx + 2).toList()..sort();
    
    if (rowNumbers.isEmpty) {
      return;
    }
    
    // Group consecutive rows into ranges to minimize API calls
    final ranges = <String, List<List<Object?>>>{};
    
    // Process rows in groups - if rows are consecutive, use a range like K2:K5
    // Otherwise, use individual cell updates
    int startRow = rowNumbers.first;
    int endRow = rowNumbers.first;
    
    for (int i = 1; i < rowNumbers.length; i++) {
      if (rowNumbers[i] == endRow + 1) {
        // Consecutive row, extend range
        endRow = rowNumbers[i];
      } else {
        // Gap found, create range for previous consecutive rows
        if (startRow == endRow) {
          ranges['Sheet1!K$startRow'] = [['']];
        } else {
          ranges['Sheet1!K$startRow:K$endRow'] = List.generate(
            endRow - startRow + 1,
            (_) => ['']
          );
        }
        startRow = rowNumbers[i];
        endRow = rowNumbers[i];
      }
    }
    
    // Add final range
    if (startRow == endRow) {
      ranges['Sheet1!K$startRow'] = [['']];
    } else {
      ranges['Sheet1!K$startRow:K$endRow'] = List.generate(
        endRow - startRow + 1,
        (_) => ['']
      );
    }
    
    // Process ranges in batches
    final rangeEntries = ranges.entries.toList();
    for (int i = 0; i < rangeEntries.length; i += maxRangesPerBatch) {
      final batch = Map.fromEntries(rangeEntries.skip(i).take(maxRangesPerBatch));
      
      try {
        await _sheetsService.batchUpdateCells(
          spreadsheetId,
          batch,
          maxRetries: 5, // More retries for batch operations
        );
      } catch (e) {
        // If batch fails, try individual updates as fallback
        for (final entry in batch.entries) {
          try {
            // Extract row numbers from range
            final range = entry.key;
            if (range.contains(':')) {
              // Range like K2:K5 - split and update individually
              final match = RegExp(r'K(\d+):K(\d+)').firstMatch(range);
              if (match != null) {
                final start = int.parse(match.group(1)!);
                final end = int.parse(match.group(2)!);
                for (int row = start; row <= end; row++) {
                  await _sheetsService.updateCells(
                    spreadsheetId,
                    'Sheet1!K$row',
                    [['']],
                    maxRetries: 3,
                  );
                }
              }
            } else {
              // Single cell
              await _sheetsService.updateCells(
                spreadsheetId,
                range,
                [['']],
                maxRetries: 3,
              );
            }
          } catch (e2) {
            // Continue with other ranges
          }
        }
      }
      
      // Add delay between batches to avoid quota errors (except for last batch)
      if (i + maxRangesPerBatch < rangeEntries.length) {
        const delayBetweenBatches = Duration(seconds: 2);
        await Future.delayed(delayBetweenBatches);
      }
    }
  }
}

