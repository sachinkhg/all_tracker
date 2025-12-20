// lib/trackers/book_tracker/core/injection.dart
// Composition root: wires data -> repository -> usecases -> cubit.

import 'package:hive_flutter/hive_flutter.dart';

import '../data/datasources/book_local_data_source.dart';
import '../data/repositories/book_repository_impl.dart';
import '../data/models/book_model.dart';
import '../domain/usecases/book/create_book.dart';
import '../domain/usecases/book/get_all_books.dart';
import '../domain/usecases/book/get_book_by_id.dart';
import '../domain/usecases/book/get_books_by_status.dart';
import '../domain/usecases/book/get_books_by_author.dart';
import '../domain/usecases/book/get_books_by_published_year.dart';
import '../domain/usecases/book/get_books_by_read_year.dart';
import '../domain/usecases/book/update_book.dart';
import '../domain/usecases/book/delete_book.dart';
import '../presentation/bloc/book_cubit.dart';
import 'constants.dart';

/// Factory that constructs a fully-wired [BookCubit].
///
/// Implementation details:
/// - This function performs an *eager, manual wiring* of concrete implementations for the feature.
/// - It assumes the Hive boxes have already been opened (typically in `main()`).
/// - All objects created here are plain Dart instances (no DI container used).
BookCubit createBookCubit() {
  // IMPORTANT: Hive.box must be already opened (open in main.dart).
  // During hot reload, boxes might not be open - check first
  if (!Hive.isBoxOpen(booksTrackerBoxName)) {
    throw StateError(
      'Book tracker box is not open. This may happen during hot reload. '
      'Please restart the app to reinitialize Hive boxes.',
    );
  }
  final Box<BookModel> box = Hive.box<BookModel>(booksTrackerBoxName);

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final local = BookLocalDataSourceImpl(box);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final repo = BookRepositoryImpl(local);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getAll = GetAllBooks(repo);
  final getById = GetBookById(repo);
  final getByStatus = GetBooksByStatus(repo);
  final getByAuthor = GetBooksByAuthor(repo);
  final getByPublishedYear = GetBooksByPublishedYear(repo);
  final getByReadYear = GetBooksByReadYear(repo);
  final create = CreateBook(repo);
  final update = UpdateBook(repo);
  final delete = DeleteBook(repo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  return BookCubit(
    getAll: getAll,
    getById: getById,
    getByStatus: getByStatus,
    getByAuthor: getByAuthor,
    getByPublishedYear: getByPublishedYear,
    getByReadYear: getByReadYear,
    create: create,
    update: update,
    delete: delete,
  );
}

