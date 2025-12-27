import '../services/google_sheets_service.dart';
import '../../../../trackers/book_tracker/domain/entities/book.dart';

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
    ];

    // Clear sheet and add headers
    await _sheetsService.clearSheet(spreadsheetId, headerRowCount: 0);
    await _sheetsService.appendRows(spreadsheetId, [headers]);
  }

  /// Write all books to the sheet (replaces existing data).
  Future<void> writeAllBooks(String spreadsheetId, List<Book> books) async {
    print('[Google Sheets] Writing ${books.length} books to sheet: $spreadsheetId');
    
    // Clear existing data (keep headers)
    print('[Google Sheets] Clearing existing data (keeping headers)');
    await _sheetsService.clearSheet(spreadsheetId, headerRowCount: 1);

    if (books.isEmpty) {
      print('[Google Sheets] No books to write');
      return;
    }

    // Convert books to rows
    print('[Google Sheets] Converting ${books.length} books to rows');
    final rows = books.map((book) => _formatBookAsRow(book)).toList();
    print('[Google Sheets] Appending ${rows.length} rows to sheet');
    await _sheetsService.appendRows(spreadsheetId, rows);
    print('[Google Sheets] Successfully wrote all books to sheet');
  }

  /// Format a book as a row for the sheet.
  List<Object?> _formatBookAsRow(Book book) {
    return [
      book.id,
      book.title,
      book.primaryAuthor,
      book.pageCount,
      book.avgRating?.toString() ?? '',
      book.datePublished?.toIso8601String() ?? '',
      book.dateStarted?.toIso8601String() ?? '',
      book.dateRead?.toIso8601String() ?? '',
      book.createdAt.toIso8601String(),
      book.updatedAt.toIso8601String(),
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
  /// Assumes the sheet has headers in row 1 and contains book data (not CRUD log).
  /// Returns a list of books parsed from the sheet data.
  Future<List<Book>> readBooksFromSheet(String spreadsheetId) async {
    final rows = await _sheetsService.readAllRows(spreadsheetId);
    if (rows.isEmpty) return [];

    // Skip header row
    final dataRows = rows.skip(1).where((row) => row.isNotEmpty && row[0] != null).toList();

    final books = <Book>[];
    for (final row in dataRows) {
      try {
        final book = _parseBookRowToBook(row);
        if (book != null) {
          books.add(book);
        }
      } catch (e) {
        // Skip invalid rows
        continue;
      }
    }

    return books;
  }

  /// Parse a book data row to a Book entity.
  Book? _parseBookRowToBook(List<Object?> row) {
    if (row.length < 10) return null;

    try {
      final bookId = row[0]?.toString() ?? '';
      final title = row[1]?.toString() ?? '';
      final author = row[2]?.toString() ?? '';
      final pageCount = int.tryParse(row[3]?.toString() ?? '') ?? 0;

      if (bookId.isEmpty || title.isEmpty || author.isEmpty || pageCount == 0) {
        return null;
      }

      final rating = row[4]?.toString().isNotEmpty == true
          ? double.tryParse(row[4]!.toString())
          : null;

      DateTime? datePublished;
      if (row[5]?.toString().isNotEmpty == true) {
        try {
          datePublished = DateTime.parse(row[5]!.toString());
        } catch (e) {
          // Ignore parse errors
        }
      }

      DateTime? dateStarted;
      if (row[6]?.toString().isNotEmpty == true) {
        try {
          dateStarted = DateTime.parse(row[6]!.toString());
        } catch (e) {
          // Ignore parse errors
        }
      }

      DateTime? dateRead;
      if (row[7]?.toString().isNotEmpty == true) {
        try {
          dateRead = DateTime.parse(row[7]!.toString());
        } catch (e) {
          // Ignore parse errors
        }
      }

      DateTime createdAt;
      try {
        createdAt = DateTime.parse(row[8]!.toString());
      } catch (e) {
        createdAt = DateTime.now();
      }

      DateTime updatedAt;
      try {
        updatedAt = DateTime.parse(row[9]!.toString());
      } catch (e) {
        updatedAt = DateTime.now();
      }

      return Book(
        id: bookId,
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
      operation.timestamp.toIso8601String(),
      operation.operation,
      operation.bookId,
      book?.title ?? '',
      book?.primaryAuthor ?? '',
      book?.pageCount ?? '',
      book?.avgRating?.toString() ?? '',
      book?.datePublished?.toIso8601String() ?? '',
      book?.dateStarted?.toIso8601String() ?? '',
      book?.dateRead?.toIso8601String() ?? '',
      '', // Notes column (reserved for future use)
    ];
  }

}

