import 'package:equatable/equatable.dart';
import '../../domain/entities/book.dart';

/// ---------------------------------------------------------------------------
/// BookState (Bloc State Definitions)
///
/// File purpose:
/// - Defines the various states used by the [BookCubit] for managing book
///   lifecycle and UI rendering.
/// - Encapsulates data and UI-relevant conditions (loading, loaded, error)
///   using immutable, equatable classes for efficient Bloc rebuilds.
///
/// State overview:
/// - [BooksLoading]: Emitted while loading books from the data source.
/// - [BooksLoaded]: Emitted when books are successfully loaded; contains a list
///   of [Book] entities.
/// - [BooksError]: Emitted when an exception or data failure occurs.
///
/// Developer guidance:
/// - States are intentionally minimal and serializable-safe (no mutable fields).
/// - Always emit new instances (avoid mutating existing state).
/// - When adding new states, ensure they extend [BookState] and override
///   `props` for correct Equatable comparisons.
///
/// ---------------------------------------------------------------------------

// Base state for book operations
abstract class BookState extends Equatable {
  const BookState();

  @override
  List<Object?> get props => [];
}

// Loading state — emitted when book data is being fetched.
class BooksLoading extends BookState {}

// Loaded state — holds the list of successfully fetched books.
class BooksLoaded extends BookState {
  final List<Book> books;

  const BooksLoaded(this.books);

  @override
  List<Object?> get props => [books];
}

// Error state — emitted when fetching or modifying books fails.
class BooksError extends BookState {
  final String message;

  const BooksError(this.message);

  @override
  List<Object?> get props => [message];
}

