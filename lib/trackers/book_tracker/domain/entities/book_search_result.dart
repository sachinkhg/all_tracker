import 'package:equatable/equatable.dart';

/// Domain entity representing a book search result from Open Library API.
///
/// This entity contains metadata about a book that can be used to auto-fill
/// book form fields when a user searches for a book by title.
class BookSearchResult extends Equatable {
  /// Title of the book.
  final String title;

  /// List of authors (primary author is typically first).
  final List<String> authors;

  /// Number of pages in the book (nullable if not available).
  final int? pageCount;

  /// Publication date (nullable if not available).
  final DateTime? datePublished;

  /// ISBN number (nullable, optional for future use).
  final String? isbn;

  /// Cover image URL (nullable, optional for future UI enhancement).
  final String? coverUrl;

  const BookSearchResult({
    required this.title,
    required this.authors,
    this.pageCount,
    this.datePublished,
    this.isbn,
    this.coverUrl,
  });

  /// Returns the primary author (first author in the list).
  String? get primaryAuthor => authors.isNotEmpty ? authors.first : null;

  @override
  List<Object?> get props => [
        title,
        authors,
        pageCount,
        datePublished,
        isbn,
        coverUrl,
      ];
}

