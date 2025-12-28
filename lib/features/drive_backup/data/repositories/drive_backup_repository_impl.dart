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

    print('[Drive Backup] Reading actions from sheet...');
    final booksWithActions = await _sheetsCrudDataSource.readBooksWithActions(config.spreadsheetId);
    
    if (booksWithActions.isEmpty) {
      print('[Drive Backup] No actions found in sheet');
      return;
    }

    print('[Drive Backup] Found ${booksWithActions.length} rows with actions');

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
      } catch (e, stackTrace) {
        print('[Drive Backup] Error processing $action action for book ${book.id}: $e');
        print('[Drive Backup] Stack trace: $stackTrace');
        // Continue processing other actions even if one fails
      }
    }

    // Update rows in sheet FIRST (before deleting to avoid row number shifts)
    // Process in descending order to avoid row number shifts during updates
    if (rowsToUpdate.isNotEmpty) {
      print('[Drive Backup] Updating ${rowsToUpdate.length} rows in sheet');
      // Sort by row number descending
      rowsToUpdate.sort((a, b) => b.rowNumber.compareTo(a.rowNumber));
      for (final updateInfo in rowsToUpdate) {
        try {
          print('[Drive Backup] Updating row ${updateInfo.rowNumber} for action ${updateInfo.action}');
          await _updateRowInSheet(config.spreadsheetId, updateInfo.rowNumber, updateInfo.updatedBook, updateInfo.action);
          print('[Drive Backup] Successfully updated row ${updateInfo.rowNumber}');
        } catch (e, stackTrace) {
          print('[Drive Backup] Error updating row ${updateInfo.rowNumber} in sheet: $e');
          print('[Drive Backup] Stack trace: $stackTrace');
          // Continue with other updates
        }
      }
    }

    // Delete rows from sheet (after updates to avoid row number shifts)
    if (rowsToDelete.isNotEmpty) {
      print('[Drive Backup] Deleting ${rowsToDelete.length} rows from sheet');
      // Remove duplicates and sort descending
      final uniqueRowsToDelete = rowsToDelete.toSet().toList()..sort((a, b) => b.compareTo(a));
      await _sheetsService.deleteRows(config.spreadsheetId, uniqueRowsToDelete);
    }

    // Clear action column for processed rows (only for non-delete actions)
    // Note: We update BEFORE deleting, so row numbers are still correct here
    if (rowsToClear.isNotEmpty) {
      print('[Drive Backup] Clearing action column for ${rowsToClear.length} processed rows');
      print('[Drive Backup] Row indices to clear: $rowsToClear');
      await _clearActionColumn(config.spreadsheetId, rowsToClear);
    }

    // Update last sync time
    final updatedConfig = config.copyWith(
      lastSheetSyncTime: DateTime.now(),
    );
    await saveConfig(updatedConfig);

    print('[Drive Backup] Successfully synced ${rowsToClear.length} actions from sheet');
  }

  /// Handle CREATE BOOK action: create a new book with its first read.
  /// 
  /// [book]: The book data from the sheet
  /// [originalBookId]: The original bookId from the sheet (may be empty for new books)
  /// Returns the created book.
  Future<Book> _handleCreateBookAction(Book book, String originalBookId) async {
    final bookId = originalBookId.trim();
    final finalBookId = bookId.isEmpty ? _uuid.v4() : bookId;
    
    print('[Drive Backup] CREATE BOOK: Creating new book with ID: $finalBookId');
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
    print('[Drive Backup] UPDATE BOOK: Updating book: ${book.id}');
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
    print('[Drive Backup] DELETE BOOK: Deleting book: $bookId');
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
    
    print('[Drive Backup] Found ${matchingRows.length} rows for book ID: $bookId');
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
    
    print('[Drive Backup] CREATE REREAD: Adding read history to book: $bookId');
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
    
    print('[Drive Backup] UPDATE REREAD: Updating read history for book: $bookId');
    
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
    
    print('[Drive Backup] DELETE REREAD: Deleting read history for book: $bookId');
    
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
      print('[Drive Backup] DELETE REREAD: Clearing current read for book: $bookId');
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
    print('[Drive Backup] DELETE REREAD: Searching readHistory for matching entry');
    print('[Drive Backup] DELETE REREAD: Target - dateStarted: $targetDateStarted, dateRead: $targetDateRead');
    print('[Drive Backup] DELETE REREAD: Current readHistory has ${existingBook.readHistory.length} entries');
    
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
      
      if (shouldDelete) {
        print('[Drive Backup] DELETE REREAD: Found matching entry to delete - '
            'dateStarted: ${entry.dateStarted}, dateRead: ${entry.dateRead}');
      }
      
      // Keep entries that should NOT be deleted
      return !shouldDelete;
    }).toList();
    
    if (updatedHistory.length == existingBook.readHistory.length) {
      print('[Drive Backup] DELETE REREAD: No matching entry found. '
          'Target dateStarted: $targetDateStarted, dateRead: $targetDateRead');
      print('[Drive Backup] DELETE REREAD: Existing readHistory entries:');
      for (int i = 0; i < existingBook.readHistory.length; i++) {
        final entry = existingBook.readHistory[i];
        print('[Drive Backup]   Entry $i: dateStarted=${entry.dateStarted}, dateRead=${entry.dateRead}');
      }
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

  /// Update a row in the sheet with book data.
  /// 
  /// For CREATE BOOK: Updates Book ID (column 0), Created At (column 8), Updated At (column 9)
  /// For UPDATE BOOK, CREATE REREAD, UPDATE REREAD: Updates Updated At (column 9) only
  Future<void> _updateRowInSheet(String spreadsheetId, int rowNumber, Book updatedBook, String action) async {
    print('[Drive Backup] _updateRowInSheet: Starting update for row $rowNumber, action: $action');
    
    // Read the existing row to preserve dateStarted/dateRead (which might represent a read history entry)
    final rows = await _sheetsService.readAllRows(spreadsheetId);
    print('[Drive Backup] _updateRowInSheet: Sheet has ${rows.length} total rows');
    
    if (rows.length < rowNumber) {
      print('[Drive Backup] ERROR: Row $rowNumber does not exist in sheet (sheet has ${rows.length} rows)');
      throw Exception('Row $rowNumber does not exist in sheet');
    }
    
    final existingRow = rows[rowNumber - 1]; // Convert to 0-based index
    print('[Drive Backup] _updateRowInSheet: Existing row has ${existingRow.length} columns');
    
    if (existingRow.isEmpty || existingRow.length < 11) {
      print('[Drive Backup] ERROR: Row $rowNumber has insufficient data (${existingRow.length} columns, need 11)');
      throw Exception('Row $rowNumber has insufficient data');
    }
    
    print('[Drive Backup] _updateRowInSheet: Row data - Book ID: ${existingRow[0]}, Title: ${existingRow[1]}');
    
    if (action == 'CREATE BOOK') {
      // CREATE BOOK: Update Book ID, Created At, Updated At
      // Read existing row and update the first row (current read) with new Book ID and timestamps
      await _sheetsService.updateRowCells(
        spreadsheetId,
        rowNumber,
        0, // Start at column A (Book ID)
        [
          updatedBook.id,
          existingRow[1], // Title (preserve)
          existingRow[2], // Author (preserve)
          existingRow[3], // Page Count (preserve)
          existingRow[4], // Rating (preserve)
          existingRow[5], // Published Date (preserve)
          existingRow[6], // Date Started (preserve)
          existingRow[7], // Date Read (preserve)
          updatedBook.createdAt.toIso8601String(), // Created At (keep timestamp)
          updatedBook.updatedAt.toIso8601String(), // Updated At (keep timestamp)
        ],
      );
      print('[Drive Backup] Updated row $rowNumber: Book ID, Created At, Updated At');
    } else {
      // UPDATE BOOK, CREATE REREAD, UPDATE REREAD: Update Updated At only (column J, index 9)
      print('[Drive Backup] Updating row $rowNumber, column J (Updated At) for action: $action');
      final updatedAtStr = updatedBook.updatedAt.toIso8601String(); // Keep timestamp
      print('[Drive Backup] Updated At value: $updatedAtStr');
      try {
        await _sheetsService.updateRowCells(
          spreadsheetId,
          rowNumber,
          9, // Start at column J (Updated At, 0-based index 9)
          [updatedAtStr],
        );
        print('[Drive Backup] Successfully updated row $rowNumber: Updated At');
      } catch (e, stackTrace) {
        print('[Drive Backup] Error updating row $rowNumber: $e');
        print('[Drive Backup] Stack trace: $stackTrace');
        rethrow;
      }
    }
  }

  /// Clear action column for specified rows.
  Future<void> _clearActionColumn(String spreadsheetId, List<int> rowIndices) async {
    // Row indices are 0-based (first data row is 0, which is row 2 in the sheet)
    // Action column is column K (index 10), which is column 11 (1-based)
    // Sheet row numbers are 1-based, so row index 0 = sheet row 2
    
    if (rowIndices.isEmpty) {
      print('[Drive Backup] No rows to clear action column');
      return;
    }

    print('[Drive Backup] Clearing action column for ${rowIndices.length} rows');
    // Clear actions one by one (Google Sheets API requires range in A1 notation)
    // Column K is the 11th column (A=1, B=2, ..., K=11)
    for (final rowIndex in rowIndices) {
      final sheetRowNumber = rowIndex + 2; // +2 because row 1 is header, data starts at row 2
      final range = 'Sheet1!K$sheetRowNumber';
      print('[Drive Backup] Clearing action in row $sheetRowNumber (range: $range, rowIndex: $rowIndex)');
      try {
        await _sheetsService.updateCells(spreadsheetId, range, [['']]);
        print('[Drive Backup] Successfully cleared action in row $sheetRowNumber');
      } catch (e, stackTrace) {
        print('[Drive Backup] Error clearing action in row $sheetRowNumber: $e');
        print('[Drive Backup] Stack trace: $stackTrace');
        // Continue with other rows
      }
    }
  }
}

