import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/read_history_entry.dart';
import '../../domain/usecases/book/get_all_books.dart';
import '../../domain/usecases/book/get_book_by_id.dart';
import '../../domain/usecases/book/get_books_by_status.dart';
import '../../domain/usecases/book/get_books_by_author.dart';
import '../../domain/usecases/book/get_books_by_published_year.dart';
import '../../domain/usecases/book/get_books_by_read_year.dart';
import '../../domain/usecases/book/create_book.dart';
import '../../domain/usecases/book/update_book.dart';
import '../../domain/usecases/book/delete_book.dart';
import '../../domain/usecases/book/get_book_stats.dart';
import '../../features/drive_backup_crud_logger.dart';
import 'book_state.dart';

/// ---------------------------------------------------------------------------
/// BookCubit
///
/// File purpose:
/// - Manages presentation state for Book entities within the Book feature.
/// - Loads, creates, updates and deletes books by delegating
///   to domain use-cases.
/// - Holds an internal master copy (`_allBooks`) and emits filtered/derived
///   views to the UI via BookState.
///
/// Developer guidance:
/// - Keep domain validation and persistence in the use-cases/repository; this
///   cubit should orchestrate and transform results for UI consumption only.
/// ---------------------------------------------------------------------------

class BookCubit extends Cubit<BookState> {
  final GetAllBooks getAll;
  final GetBookById getById;
  final GetBooksByStatus getByStatus;
  final GetBooksByAuthor getByAuthor;
  final GetBooksByPublishedYear getByPublishedYear;
  final GetBooksByReadYear getByReadYear;
  final CreateBook create;
  final UpdateBook update;
  final DeleteBook delete;
  final DriveBackupCrudLogger? _crudLogger;

  // master copy of all books fetched from the domain layer.
  List<Book> _allBooks = [];

  BookCubit({
    required this.getAll,
    required this.getById,
    required this.getByStatus,
    required this.getByAuthor,
    required this.getByPublishedYear,
    required this.getByReadYear,
    required this.create,
    required this.update,
    required this.delete,
    DriveBackupCrudLogger? crudLogger,
  })  : _crudLogger = crudLogger,
        super(BooksLoading());

  /// Loads all books from the repository.
  Future<void> loadBooks() async {
    emit(BooksLoading());
    try {
      _allBooks = await getAll();
      emit(BooksLoaded(_allBooks));
    } catch (e, stackTrace) {
      print('Error loading books: $e');
      print('Stack trace: $stackTrace');
      emit(BooksError('Failed to load books: $e'));
    }
  }

  /// Gets a book by its ID.
  Future<Book?> getBookById(String id) async {
    try {
      return await getById(id);
    } catch (e) {
      emit(BooksError('Failed to get book: $e'));
      return null;
    }
  }

  /// Gets books by status.
  Future<List<Book>> getBooksByStatus(status) async {
    try {
      return await getByStatus(status);
    } catch (e) {
      emit(BooksError('Failed to get books by status: $e'));
      return [];
    }
  }

  /// Gets books by author.
  Future<List<Book>> getBooksByAuthor(String author) async {
    try {
      return await getByAuthor(author);
    } catch (e) {
      emit(BooksError('Failed to get books by author: $e'));
      return [];
    }
  }

  /// Gets books by published year.
  Future<List<Book>> getBooksByPublishedYear(int year) async {
    try {
      return await getByPublishedYear(year);
    } catch (e) {
      emit(BooksError('Failed to get books by published year: $e'));
      return [];
    }
  }

  /// Gets books by read year.
  Future<List<Book>> getBooksByReadYear(int year) async {
    try {
      return await getByReadYear(year);
    } catch (e) {
      emit(BooksError('Failed to get books by read year: $e'));
      return [];
    }
  }

  /// Creates a new book.
  Future<void> createBook({
    required String title,
    required String primaryAuthor,
    required int pageCount,
    double? avgRating,
    DateTime? datePublished,
    DateTime? dateStarted,
    DateTime? dateRead,
  }) async {
    try {
      final now = DateTime.now();
      final newBook = Book(
        id: const Uuid().v4(),
        title: title,
        primaryAuthor: primaryAuthor,
        pageCount: pageCount,
        avgRating: avgRating,
        datePublished: datePublished,
        dateStarted: dateStarted,
        dateRead: dateRead,
        createdAt: now,
        updatedAt: now,
      );

      await create(newBook);
      // Log CRUD operation for Drive backup
      _crudLogger?.logCreate(newBook);
      // Reload to get updated list - ensure we're in a good state first
      _allBooks = [];
      await loadBooks(); // Reload to get updated list
    } catch (e, stackTrace) {
      print('Error creating book: $e');
      print('Stack trace: $stackTrace');
      emit(BooksError('Failed to create book: $e'));
      // Try to reload anyway to get current state
      try {
        await loadBooks();
      } catch (_) {
        // If reload also fails, keep the error state
      }
    }
  }

  /// Updates an existing book.
  Future<void> updateBook(Book book) async {
    try {
      final updatedBook = book.copyWith(
        updatedAt: DateTime.now(),
      );
      await update(updatedBook);
      // Log CRUD operation for Drive backup
      _crudLogger?.logUpdate(updatedBook);
      await loadBooks(); // Reload to get updated list
    } catch (e) {
      emit(BooksError('Failed to update book: $e'));
    }
  }

  /// Deletes a book by its ID.
  Future<void> deleteBook(String id) async {
    try {
      await delete(id);
      // Log CRUD operation for Drive backup
      _crudLogger?.logDelete(id);
      await loadBooks(); // Reload to get updated list
    } catch (e) {
      emit(BooksError('Failed to delete book: $e'));
    }
  }

  /// Gets book statistics.
  Future<BookStats> getStats() async {
    final getStats = GetBookStats(getAll.repository);
    return await getStats();
  }

  /// Removes a specific read history entry from a book.
  ///
  /// Removes the read history entry at the specified index.
  /// Returns the updated book so the form can update its state.
  Future<Book?> removeReadHistoryEntry(Book book, int index) async {
    try {
      if (index < 0 || index >= book.readHistory.length) {
        return null;
      }
      
      final updatedHistory = List<ReadHistoryEntry>.from(book.readHistory);
      updatedHistory.removeAt(index);
      
      final updatedBook = book.copyWith(
        readHistory: updatedHistory,
        updatedAt: DateTime.now(),
      );
      
      await update(updatedBook);
      // Log CRUD operation for Drive backup
      _crudLogger?.logUpdate(updatedBook);
      await loadBooks();
      
      return updatedBook;
    } catch (e) {
      emit(BooksError('Failed to remove read history entry: $e'));
      return null;
    }
  }

  /// Archives the current read and starts a new reading cycle.
  ///
  /// This is the "re-read" functionality. If the book has dateStarted and dateRead,
  /// it appends them to readHistory and clears the active dates.
  /// Returns the updated book so the form can update its state.
  Future<Book?> reReadBook(Book book) async {
    try {
      Book updatedBook;
      
      // If current read is completed, archive it to history
      if (book.dateStarted != null && book.dateRead != null) {
        final historyEntry = ReadHistoryEntry(
          dateStarted: book.dateStarted,
          dateRead: book.dateRead,
        );
        final updatedHistory = [...book.readHistory, historyEntry];
        
        updatedBook = book.copyWith(
          readHistory: updatedHistory,
          dateStarted: null,
          dateRead: null,
          updatedAt: DateTime.now(),
        );
        await update(updatedBook);
      } else {
        // Just clear the dates if not completed
        updatedBook = book.copyWith(
          dateStarted: null,
          dateRead: null,
          updatedAt: DateTime.now(),
        );
        await update(updatedBook);
      }
      
      // Reload to get updated list
      await loadBooks();
      
      // Return the updated book
      return updatedBook;
    } catch (e) {
      emit(BooksError('Failed to re-read book: $e'));
      return null;
    }
  }
}

