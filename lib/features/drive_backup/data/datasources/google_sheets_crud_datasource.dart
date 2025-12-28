import '../services/google_sheets_service.dart';
import '../../../../trackers/book_tracker/domain/entities/book.dart';
import '../../../../trackers/book_tracker/domain/entities/read_history_entry.dart';

/// Internal data class for parsing book row data.
class _BookRowData {
  final String bookId;
  final String title;
  final String primaryAuthor;
  final int pageCount;
  final double? avgRating;
  final DateTime? datePublished;
  final DateTime? dateStarted;
  final DateTime? dateRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  _BookRowData({
    required this.bookId,
    required this.title,
    required this.primaryAuthor,
    required this.pageCount,
    this.avgRating,
    this.datePublished,
    this.dateStarted,
    this.dateRead,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Represents a CRUD operation on a book.
class BookCrudOperation {
  final DateTime timestamp;
  final String operation; // 'CREATE', 'UPDATE', 'DELETE'
  final Book? book; // null for DELETE operations
  final String? bookId; // always present

  BookCrudOperation({
    required this.timestamp,
    required this.operation,
    this.book,
    required this.bookId,
  });
}

/// Data source for Google Sheets CRUD operations.
class GoogleSheetsCrudDataSource {
  final GoogleSheetsService _sheetsService;

  GoogleSheetsCrudDataSource(this._sheetsService);

  /// Initialize the spreadsheet with headers for book data.
  Future<void> initializeSheet(String spreadsheetId) async {
    final headers = [
      'Book ID',
      'Title',
      'Author',
      'Page Count',
      'Rating',
      'Published Date',
      'Date Started',
      'Date Read',
      'Created At',
      'Updated At',
      'Action', // CREATE BOOK, UPDATE BOOK, DELETE BOOK, CREATE REREAD, UPDATE REREAD, DELETE REREAD, or empty
    ];

    // Clear sheet and add headers
    await _sheetsService.clearSheet(spreadsheetId, headerRowCount: 0);
    await _sheetsService.appendRows(spreadsheetId, [headers]);
    
    // Apply formatting (header color, font, dropdown)
    await _sheetsService.formatSheet(spreadsheetId);
  }

  /// Write all books to the sheet (replaces existing data).
  /// 
  /// Creates multiple rows per book:
  /// - One row for the current read (dateStarted/dateRead from the book)
  /// - One row for each entry in readHistory
  Future<void> writeAllBooks(String spreadsheetId, List<Book> books) async {
    print('[Google Sheets] Writing ${books.length} books to sheet: $spreadsheetId');
    
    // Clear existing data (keep headers)
    print('[Google Sheets] Clearing existing data (keeping headers)');
    await _sheetsService.clearSheet(spreadsheetId, headerRowCount: 1);

    if (books.isEmpty) {
      print('[Google Sheets] No books to write');
      return;
    }

    // Convert books to rows (one row per read entry)
    print('[Google Sheets] Converting ${books.length} books to rows');
    final rows = <List<Object?>>[];
    for (final book in books) {
      // First row: current read (main book data with current dateStarted/dateRead)
      rows.add(_formatBookAsRow(book));
      
      // Additional rows: one for each read history entry
      for (final historyEntry in book.readHistory) {
        // Create a row with the same book data but different dates from history entry
        rows.add(_formatBookAsRowWithHistory(book, historyEntry));
      }
    }
    
    print('[Google Sheets] Appending ${rows.length} rows to sheet (${books.length} books with read history)');
    await _sheetsService.appendRows(spreadsheetId, rows);
    print('[Google Sheets] Successfully wrote all books to sheet');
  }

  /// Format a date as date-only string (YYYY-MM-DD).
  String? _formatDateOnly(DateTime? date) {
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Parse a date string that may be in various formats (ISO8601, date-only, or Google Sheets format).
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    
    try {
      // Try ISO8601 format first (e.g., "2018-09-20T00:00:00.000Z")
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      }
      
      // Try date-only format (YYYY-MM-DD)
      if (dateStr.length == 10 && dateStr[4] == '-' && dateStr[7] == '-') {
        return DateTime.parse(dateStr);
      }
      
      // Try Google Sheets date format (DD/MM/YYYY or DD/MM/YYYY HH:mm:ss)
      if (dateStr.contains('/')) {
        final parts = dateStr.split(' ');
        final datePart = parts[0]; // Get just the date part (before space)
        final dateComponents = datePart.split('/');
        if (dateComponents.length == 3) {
          // DD/MM/YYYY format
          final day = int.parse(dateComponents[0]);
          final month = int.parse(dateComponents[1]);
          final year = int.parse(dateComponents[2]);
          return DateTime(year, month, day);
        }
      }
      
      // Fallback to standard parse
      return DateTime.parse(dateStr);
    } catch (e) {
      print('[Google Sheets] Error parsing date "$dateStr": $e');
      return null;
    }
  }

  /// Format a book as a row for the sheet (using current read dates).
  List<Object?> _formatBookAsRow(Book book, {String? action}) {
    return [
      book.id,
      book.title,
      book.primaryAuthor,
      book.pageCount,
      book.avgRating?.toString() ?? '',
      _formatDateOnly(book.datePublished) ?? '',
      _formatDateOnly(book.dateStarted) ?? '',
      _formatDateOnly(book.dateRead) ?? '',
      book.createdAt.toIso8601String(), // Keep timestamp for Created At
      book.updatedAt.toIso8601String(), // Keep timestamp for Updated At
      action ?? '', // Action column
    ];
  }

  /// Format a book row with a specific read history entry (different dates).
  List<Object?> _formatBookAsRowWithHistory(Book book, ReadHistoryEntry historyEntry, {String? action}) {
    return [
      book.id,
      book.title,
      book.primaryAuthor,
      book.pageCount,
      book.avgRating?.toString() ?? '',
      _formatDateOnly(book.datePublished) ?? '',
      _formatDateOnly(historyEntry.dateStarted) ?? '',
      _formatDateOnly(historyEntry.dateRead) ?? '',
      book.createdAt.toIso8601String(), // Keep timestamp for Created At
      book.updatedAt.toIso8601String(), // Keep timestamp for Updated At
      action ?? '', // Action column
    ];
  }

  /// Append a CRUD operation to the sheet.
  Future<void> appendOperation(String spreadsheetId, BookCrudOperation operation) async {
    final row = _formatOperationAsRow(operation);
    await _sheetsService.appendRows(spreadsheetId, [row]);
  }

  /// Append multiple CRUD operations to the sheet.
  Future<void> appendOperations(String spreadsheetId, List<BookCrudOperation> operations) async {
    if (operations.isEmpty) return;

    final rows = operations.map((op) => _formatOperationAsRow(op)).toList();
    await _sheetsService.appendRows(spreadsheetId, rows);
  }

  /// Read all books from the sheet.
  /// 
  /// Groups rows by Book ID and reconstructs books with read history.
  /// - Multiple rows with the same Book ID are treated as multiple reads
  /// - The row with the most recent dateRead (or dateStarted if no dateRead) becomes the current read
  /// - Other rows become readHistory entries
  Future<List<Book>> readBooksFromSheet(String spreadsheetId) async {
    final rows = await _sheetsService.readAllRows(spreadsheetId);
    if (rows.isEmpty) return [];

    // Skip header row
    final dataRows = rows.skip(1).where((row) => row.isNotEmpty && row[0] != null).toList();

    // Group rows by Book ID
    final rowsByBookId = <String, List<_BookRowData>>{};
    
    for (final row in dataRows) {
      try {
        final rowData = _parseBookRowData(row);
        if (rowData != null) {
          rowsByBookId.putIfAbsent(rowData.bookId, () => []).add(rowData);
        }
      } catch (e) {
        // Skip invalid rows
        continue;
      }
    }

    // Reconstruct books from grouped rows
    final books = <Book>[];
    for (final entry in rowsByBookId.entries) {
      final bookId = entry.key;
      final rowsForBook = entry.value;
      
      if (rowsForBook.isEmpty) continue;
      
      // Sort rows by dateRead (most recent first), then by dateStarted
      rowsForBook.sort((a, b) {
        final aDate = a.dateRead ?? a.dateStarted;
        final bDate = b.dateRead ?? b.dateStarted;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate); // Most recent first
      });
      
      // First row becomes the main book (current read)
      final mainRow = rowsForBook.first;
      final readHistory = <ReadHistoryEntry>[];
      
      // Remaining rows become read history entries
      for (int i = 1; i < rowsForBook.length; i++) {
        final historyRow = rowsForBook[i];
        readHistory.add(ReadHistoryEntry(
          dateStarted: historyRow.dateStarted,
          dateRead: historyRow.dateRead,
        ));
      }
      
      // Create the book with main row data and read history
      final book = Book(
        id: bookId,
        title: mainRow.title,
        primaryAuthor: mainRow.primaryAuthor,
        pageCount: mainRow.pageCount,
        avgRating: mainRow.avgRating,
        datePublished: mainRow.datePublished,
        dateStarted: mainRow.dateStarted,
        dateRead: mainRow.dateRead,
        readHistory: readHistory,
        createdAt: mainRow.createdAt,
        updatedAt: mainRow.updatedAt,
      );
      
      books.add(book);
    }

    return books;
  }

  /// Parse a book row and return row data (doesn't create Book entity yet).
  _BookRowData? _parseBookRowData(List<Object?> row) {
    // Now we have 11 columns including Action, but for parsing we still need at least 10
    if (row.length < 10) return null;

    try {
      final bookId = row[0]?.toString() ?? '';
      final title = row[1]?.toString() ?? '';
      final author = row[2]?.toString() ?? '';
      final pageCount = int.tryParse(row[3]?.toString() ?? '') ?? 0;

      // Title and author are required
      if (title.isEmpty || author.isEmpty) {
        return null;
      }

      final rating = row[4]?.toString().isNotEmpty == true
          ? double.tryParse(row[4]!.toString())
          : null;

      DateTime? datePublished = _parseDate(row[5]?.toString());
      DateTime? dateStarted = _parseDate(row[6]?.toString());
      DateTime? dateRead = _parseDate(row[7]?.toString());
      
      DateTime createdAt = _parseDate(row[8]?.toString()) ?? DateTime.now();
      DateTime updatedAt = _parseDate(row[9]?.toString()) ?? DateTime.now();

      return _BookRowData(
        bookId: bookId.isEmpty ? 'temp-placeholder' : bookId,
        title: title,
        primaryAuthor: author,
        pageCount: pageCount,
        avgRating: rating,
        datePublished: datePublished,
        dateStarted: dateStarted,
        dateRead: dateRead,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      return null;
    }
  }

  /// Read books with actions from the sheet.
  /// 
  /// Returns a map of row index (0-based, excluding header) to a record with book, action, and originalBookId.
  /// Only returns rows that have an action specified (CREATE, UPDATE, DELETE).
  /// originalBookId is the bookId from the sheet (may be empty for CREATE actions).
  Future<Map<int, ({Book book, String action, String originalBookId})>> readBooksWithActions(String spreadsheetId) async {
    final rows = await _sheetsService.readAllRows(spreadsheetId);
    if (rows.isEmpty) return {};

    // Skip header row (row index 0 is first data row)
    final dataRows = rows.skip(1).toList();
    final result = <int, ({Book book, String action, String originalBookId})>{};

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      if (row.isEmpty) continue;

      // Check if action column exists (column index 10)
      final action = row.length > 10 ? (row[10]?.toString().trim().toUpperCase() ?? '') : '';
      final validActions = [
        'CREATE BOOK',
        'UPDATE BOOK',
        'DELETE BOOK',
        'CREATE REREAD',
        'UPDATE REREAD',
        'DELETE REREAD',
      ];
      if (action.isEmpty || !validActions.contains(action)) {
        continue; // Skip rows without valid actions
      }

      // Get original bookId from the row (column index 0)
      final originalBookId = row.length > 0 ? (row[0]?.toString().trim() ?? '') : '';

      try {
        final book = _parseBookRowToBook(row);
        if (book != null) {
          result[i] = (book: book, action: action, originalBookId: originalBookId);
        }
      } catch (e) {
        // Skip invalid rows
        continue;
      }
    }

    return result;
  }

  /// Parse a book data row to a Book entity.
  Book? _parseBookRowToBook(List<Object?> row) {
    // Now we have 11 columns including Action, but for parsing we still need at least 10
    if (row.length < 10) return null;

    try {
      final bookId = row[0]?.toString() ?? '';
      final title = row[1]?.toString() ?? '';
      final author = row[2]?.toString() ?? '';
      final pageCount = int.tryParse(row[3]?.toString() ?? '') ?? 0;

      // For CREATE actions, bookId might be empty (will be generated)
      // Title and author are required, but pageCount might be 0 for new entries
      if (title.isEmpty || author.isEmpty) {
        return null;
      }

      final rating = row[4]?.toString().isNotEmpty == true
          ? double.tryParse(row[4]!.toString())
          : null;

      DateTime? datePublished = _parseDate(row[5]?.toString());
      DateTime? dateStarted = _parseDate(row[6]?.toString());
      DateTime? dateRead = _parseDate(row[7]?.toString());
      
      DateTime createdAt = _parseDate(row[8]?.toString()) ?? DateTime.now();
      DateTime updatedAt = _parseDate(row[9]?.toString()) ?? DateTime.now();

      return Book(
        id: bookId.isEmpty ? 'temp-placeholder' : bookId,
        title: title,
        primaryAuthor: author,
        pageCount: pageCount,
        avgRating: rating,
        datePublished: datePublished,
        dateStarted: dateStarted,
        dateRead: dateRead,
        readHistory: [], // Read history not stored in sheet
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      return null;
    }
  }

  /// Format a CRUD operation as a row for the sheet.
  List<Object?> _formatOperationAsRow(BookCrudOperation operation) {
    final book = operation.book;
    return [
      _formatDateOnly(operation.timestamp) ?? '',
      operation.operation,
      operation.bookId,
      book?.title ?? '',
      book?.primaryAuthor ?? '',
      book?.pageCount ?? '',
      book?.avgRating?.toString() ?? '',
      _formatDateOnly(book?.datePublished) ?? '',
      _formatDateOnly(book?.dateStarted) ?? '',
      _formatDateOnly(book?.dateRead) ?? '',
      '', // Notes column (reserved for future use)
    ];
  }

}

