/*
 * File: book_repository_impl.dart
 *
 * Purpose:
 *   Concrete implementation of BookRepository that uses BookLocalDataSource
 *   for persistence. This class bridges the domain layer (entities) and data layer (models).
 *
 * Responsibilities:
 *   - Convert between domain entities (Book) and data models (BookModel)
 *   - Delegate persistence operations to BookLocalDataSource
 *   - Handle any data layer specific logic (filtering, sorting, etc.)
 *
 * Developer notes:
 *   - This implementation is intentionally thin — most logic should be in use cases or the data source.
 *   - Conversion between Book and BookModel is handled by the model's fromEntity/toEntity methods.
 */

import '../../domain/entities/book.dart';
import '../../domain/entities/book_status.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_local_data_source.dart';
import '../models/book_model.dart';

/// Concrete implementation of [BookRepository] using Hive for persistence.
class BookRepositoryImpl implements BookRepository {
  final BookLocalDataSource dataSource;

  BookRepositoryImpl(this.dataSource);

  @override
  Future<List<Book>> getAllBooks() async {
    final models = await dataSource.getAllBooks();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Book?> getBookById(String id) async {
    final model = await dataSource.getBookById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Book>> getBooksByStatus(BookStatus status) async {
    final models = await dataSource.getBooksByStatus(status);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Book>> getBooksByAuthor(String author) async {
    final models = await dataSource.getBooksByAuthor(author);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Book>> getBooksByPublishedYear(int year) async {
    final models = await dataSource.getBooksByPublishedYear(year);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Book>> getBooksByReadYear(int year) async {
    final models = await dataSource.getBooksByReadYear(year);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> createBook(Book book) async {
    final model = BookModel.fromEntity(book);
    await dataSource.createBook(model);
  }

  @override
  Future<void> updateBook(Book book) async {
    final model = BookModel.fromEntity(book);
    await dataSource.updateBook(model);
  }

  @override
  Future<void> deleteBook(String id) async {
    await dataSource.deleteBook(id);
  }
}

