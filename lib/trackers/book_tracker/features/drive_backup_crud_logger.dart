import '../domain/entities/book.dart';
import '../../../../features/drive_backup/data/datasources/google_sheets_crud_datasource.dart';

/// Logger for tracking CRUD operations on books for Drive backup.
/// 
/// Queues operations that will be synced to Google Sheets during backup.
class DriveBackupCrudLogger {
  final List<BookCrudOperation> _operationQueue = [];

  /// Log a CREATE operation.
  void logCreate(Book book) {
    _operationQueue.add(BookCrudOperation(
      timestamp: DateTime.now(),
      operation: 'CREATE',
      book: book,
      bookId: book.id,
    ));
  }

  /// Log an UPDATE operation.
  void logUpdate(Book book) {
    _operationQueue.add(BookCrudOperation(
      timestamp: DateTime.now(),
      operation: 'UPDATE',
      book: book,
      bookId: book.id,
    ));
  }

  /// Log a DELETE operation.
  void logDelete(String bookId) {
    _operationQueue.add(BookCrudOperation(
      timestamp: DateTime.now(),
      operation: 'DELETE',
      book: null,
      bookId: bookId,
    ));
  }

  /// Get all queued operations.
  List<BookCrudOperation> getQueuedOperations() {
    return List.unmodifiable(_operationQueue);
  }

  /// Clear the operation queue.
  void clearQueue() {
    _operationQueue.clear();
  }

  /// Get the number of queued operations.
  int get queueLength => _operationQueue.length;
}

