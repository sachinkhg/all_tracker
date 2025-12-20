import '../entities/book.dart';
import '../entities/book_status.dart';

/// Abstract repository interface for book operations.
///
/// This interface defines the contract for book data access operations.
/// Implementations should handle persistence, filtering, and querying logic.
abstract class BookRepository {
  /// Retrieves all books.
  ///
  /// Returns a list of all books in the repository.
  /// Returns an empty list if no books exist.
  Future<List<Book>> getAllBooks();

  /// Retrieves a book by its unique identifier.
  ///
  /// Returns the book if found, null otherwise.
  Future<Book?> getBookById(String id);

  /// Retrieves books filtered by status.
  ///
  /// Returns all books that match the specified status.
  Future<List<Book>> getBooksByStatus(BookStatus status);

  /// Retrieves books filtered by author.
  ///
  /// Returns all books where the primaryAuthor matches (case-insensitive partial match).
  Future<List<Book>> getBooksByAuthor(String author);

  /// Retrieves books filtered by publication year.
  ///
  /// Returns all books published in the specified year.
  Future<List<Book>> getBooksByPublishedYear(int year);

  /// Retrieves books filtered by read year (based on latest dateRead).
  ///
  /// Returns all books where the latest dateRead falls in the specified year.
  Future<List<Book>> getBooksByReadYear(int year);

  /// Creates a new book.
  ///
  /// Throws an exception if the book cannot be created.
  Future<void> createBook(Book book);

  /// Updates an existing book.
  ///
  /// Throws an exception if the book does not exist or cannot be updated.
  Future<void> updateBook(Book book);

  /// Deletes a book by its unique identifier.
  ///
  /// Throws an exception if the book does not exist or cannot be deleted.
  Future<void> deleteBook(String id);
}

