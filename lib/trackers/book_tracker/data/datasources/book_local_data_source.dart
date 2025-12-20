/*
 * File: book_local_data_source.dart
 *
 * Purpose:
 *   Hive-backed local data source for Book objects. This file provides an
 *   abstract contract (BookLocalDataSource) and a Hive implementation
 *   (BookLocalDataSourceImpl) that persist BookModel instances into a Hive box.
 *
 * Serialization rules (high level):
 *   - The concrete Hive adapter and the BookModel DTO live in ../models/book_model.dart.
 *   - Nullable fields, defaults, and any custom conversion are defined on BookModel.
 *     Refer to BookModel for which fields are nullable and default values.
 *   - Keys used for storage: book.id (String) is used as the Hive key (not an auto-increment).
 *
 * Compatibility guidance:
 *   - Do NOT reuse Hive field numbers in book_model.dart when adding/removing fields.
 *   - When changing the model layout or field numbers, update migration_notes.md
 *     with the adapter version and migration steps.
 *   - Any backward-compatibility conversions (legacy values -> new schema) should be
 *     implemented in BookModel (factory / fromEntity / fromJson) so the data source
 *     remains thin and focused on persistence.
 *
 * Developer notes:
 *   - This file intentionally does not perform model conversions — it delegates that
 *     responsibility to BookModel. Keep storage operations (put/get/delete) simple.
 *   - If you add caching, locking, or batch operations, maintain the invariant that
 *     keys are book.id and that BookModel instances match the Hive adapter version.
 */

import 'package:hive/hive.dart';
import '../models/book_model.dart';
import '../../domain/entities/book_status.dart';

/// Abstract data source for local (Hive) book storage.
///
/// Implementations should be simple adapters that read/write BookModel instances.
/// Conversions between domain entity and DTO should be implemented in BookModel.
abstract class BookLocalDataSource {
  /// Returns all books stored in the local box.
  Future<List<BookModel>> getAllBooks();

  /// Returns a single BookModel by its string id key, or null if not found.
  Future<BookModel?> getBookById(String id);

  /// Returns books filtered by status.
  Future<List<BookModel>> getBooksByStatus(BookStatus status);

  /// Returns books filtered by author (case-insensitive partial match).
  Future<List<BookModel>> getBooksByAuthor(String author);

  /// Returns books filtered by publication year.
  Future<List<BookModel>> getBooksByPublishedYear(int year);

  /// Returns books filtered by read year (based on latest dateRead).
  Future<List<BookModel>> getBooksByReadYear(int year);

  /// Persists a new BookModel. The implementation is expected to use book.id as key.
  Future<void> createBook(BookModel book);

  /// Updates an existing BookModel (or creates it if missing) — uses the same
  /// semantics as Hive's `put` (overwrite if exists).
  Future<void> updateBook(BookModel book);

  /// Deletes a book by its id key.
  Future<void> deleteBook(String id);
}

/// Hive implementation of [BookLocalDataSource].
///
/// This class treats the provided [box] as the single source of truth for
/// BookModel persistence. It uses `book.id` (String) as the Hive key — this keeps
/// keys stable across app runs and simplifies lookup.
///
/// Important:
///  - Any legacy value handling (e.g. migrating an old string format to a new enum)
///    should be done inside BookModel (e.g., BookModel.fromEntity/fromJson).
///  - The box must be registered with the appropriate adapter for BookModel before
///    this class is constructed.
class BookLocalDataSourceImpl implements BookLocalDataSource {
  /// Hive box that stores [BookModel] entries.
  ///
  /// Rationale: using a typed Box<BookModel> enforces compile-time safety and
  /// ensures the Hive adapter for BookModel is used for serialization.
  final Box<BookModel> box;

  /// Create the local data source with the provided Hive box.
  ///
  /// The box should be opened and the BookModel adapter registered prior to
  /// passing it here (typically during app initialization in core/hive initializer).
  BookLocalDataSourceImpl(this.box);

  @override
  Future<void> createBook(BookModel book) async {
    // Use book.id as the key. This keeps keys consistent and human-readable.
    // We intentionally rely on Hive's `put` semantics — it will create or overwrite.
    await box.put(book.id, book);
  }

  @override
  Future<void> deleteBook(String id) async {
    // Remove the entry with the given id key. No additional logic here to keep
    // the data source thin; domain-level cascade deletes (if any) should be handled
    // by the repository/usecase layer.
    await box.delete(id);
  }

  @override
  Future<BookModel?> getBookById(String id) async {
    // Direct box lookup by string key. Returns null if not present.
    // If additional compatibility work is needed (e.g. rehydration), implement it
    // in BookModel (constructor/factory) so this call remains simple.
    return box.get(id);
  }

  @override
  Future<List<BookModel>> getAllBooks() async {
    // Convert box values iterable to a list. Ordering is the insertion order from Hive.
    // If deterministic sorting is required (e.g., by date), do it at the
    // repository/presentation layer rather than here.
    return box.values.toList();
  }

  @override
  Future<List<BookModel>> getBooksByStatus(BookStatus status) async {
    final allBooks = box.values.toList();
    return allBooks.where((book) {
      // Determine status from book dates
      if (status == BookStatus.completed) {
        return book.dateRead != null;
      } else if (status == BookStatus.reading) {
        return book.dateStarted != null && book.dateRead == null;
      } else {
        // notStarted
        return book.dateStarted == null;
      }
    }).toList();
  }

  @override
  Future<List<BookModel>> getBooksByAuthor(String author) async {
    final allBooks = box.values.toList();
    final authorLower = author.toLowerCase();
    return allBooks
        .where((book) =>
            book.primaryAuthor.toLowerCase().contains(authorLower))
        .toList();
  }

  @override
  Future<List<BookModel>> getBooksByPublishedYear(int year) async {
    final allBooks = box.values.toList();
    return allBooks.where((book) {
      if (book.datePublished == null) return false;
      return book.datePublished!.year == year;
    }).toList();
  }

  @override
  Future<List<BookModel>> getBooksByReadYear(int year) async {
    final allBooks = box.values.toList();
    return allBooks.where((book) {
      // Check latest dateRead (current read)
      if (book.dateRead != null && book.dateRead!.year == year) {
        return true;
      }
      // Check readHistory for completed reads in that year
      if (book.readHistory != null) {
        return book.readHistory!.any((entry) =>
            entry.dateRead != null && entry.dateRead!.year == year);
      }
      return false;
    }).toList();
  }

  @override
  Future<void> updateBook(BookModel book) async {
    // Update uses the same `put` as create — overwrites existing entry with same key.
    // This keeps create/update semantics unified and reduces duplication.
    await box.put(book.id, book);
  }
}

