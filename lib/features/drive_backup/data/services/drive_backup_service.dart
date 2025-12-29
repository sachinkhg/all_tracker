import 'package:hive_flutter/hive_flutter.dart';
import '../../../../trackers/book_tracker/core/constants.dart';
import '../../../../trackers/book_tracker/data/models/book_model.dart';
import '../../../../trackers/book_tracker/domain/entities/book.dart';
import '../../../../trackers/book_tracker/domain/entities/read_history_entry.dart';

/// Service for orchestrating Drive backup operations.
class DriveBackupService {
  /// Get all books from Hive.
  Future<List<Book>> getAllBooks() async {
    final booksBox = Hive.box<BookModel>(booksTrackerBoxName);
    final books = booksBox.values.toList();
    return books.map((model) => model.toEntity()).toList();
  }

  /// Serialize all books to JSON format.
  Future<Map<String, dynamic>> serializeBooksToJson() async {
    final booksBox = Hive.box<BookModel>(booksTrackerBoxName);
    final books = booksBox.values.toList();

    return {
      'version': '1',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'books':       books.map((book) => {
            'id': book.id,
            'title': book.title,
            'primaryAuthor': book.primaryAuthor,
            'pageCount': book.pageCount,
            'selfRating': book.selfRating,
            'datePublished': book.datePublished?.toUtc().toIso8601String(),
            'dateStarted': book.dateStarted?.toUtc().toIso8601String(),
            'dateRead': book.dateRead?.toUtc().toIso8601String(),
            'readHistory': book.readHistory?.map((entry) => {
                  'dateStarted': entry.dateStarted?.toUtc().toIso8601String(),
                  'dateRead': entry.dateRead?.toUtc().toIso8601String(),
                }).toList() ?? [],
            'createdAt': book.createdAt.toUtc().toIso8601String(),
            'updatedAt': book.updatedAt.toUtc().toIso8601String(),
          }).toList(),
    };
  }

  /// Deserialize books from JSON format.
  List<Book> deserializeBooksFromJson(Map<String, dynamic> json) {
    final booksJson = json['books'] as List<dynamic>? ?? [];
    final books = <Book>[];

    for (final bookJson in booksJson) {
      try {
        final book = _parseBookFromJson(bookJson as Map<String, dynamic>);
        if (book != null) {
          books.add(book);
        }
      } catch (e) {
        // Skip invalid books
        continue;
      }
    }

    return books;
  }

  /// Parse a book from JSON.
  Book? _parseBookFromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String?;
      final title = json['title'] as String?;
      final author = json['primaryAuthor'] as String?;
      final pageCount = json['pageCount'] as int?;

      if (id == null || title == null || author == null || pageCount == null) {
        return null;
      }

      final selfRating = json['selfRating'] != null
          ? (json['selfRating'] as num).toDouble()
          : null;

      DateTime? datePublished;
      if (json['datePublished'] != null) {
        try {
          datePublished = DateTime.parse(json['datePublished'] as String);
        } catch (e) {
          // Ignore parse errors
        }
      }

      DateTime? dateStarted;
      if (json['dateStarted'] != null) {
        try {
          dateStarted = DateTime.parse(json['dateStarted'] as String);
        } catch (e) {
          // Ignore parse errors
        }
      }

      DateTime? dateRead;
      if (json['dateRead'] != null) {
        try {
          dateRead = DateTime.parse(json['dateRead'] as String);
        } catch (e) {
          // Ignore parse errors
        }
      }

      final readHistoryJson = json['readHistory'] as List<dynamic>? ?? [];
      final readHistory = readHistoryJson.map((entryJson) {
        final entry = entryJson as Map<String, dynamic>;
        DateTime? entryDateStarted;
        if (entry['dateStarted'] != null) {
          try {
            entryDateStarted = DateTime.parse(entry['dateStarted'] as String);
          } catch (e) {
            // Ignore
          }
        }
        DateTime? entryDateRead;
        if (entry['dateRead'] != null) {
          try {
            entryDateRead = DateTime.parse(entry['dateRead'] as String);
          } catch (e) {
            // Ignore
          }
        }
        return ReadHistoryEntry(
          dateStarted: entryDateStarted,
          dateRead: entryDateRead,
        );
      }).toList();

      DateTime createdAt;
      try {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } catch (e) {
        createdAt = DateTime.now();
      }

      DateTime updatedAt;
      try {
        updatedAt = DateTime.parse(json['updatedAt'] as String);
      } catch (e) {
        updatedAt = DateTime.now();
      }

      return Book(
        id: id,
        title: title,
        primaryAuthor: author,
        pageCount: pageCount,
        selfRating: selfRating,
        datePublished: datePublished,
        dateStarted: dateStarted,
        dateRead: dateRead,
        readHistory: readHistory,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      return null;
    }
  }

  /// Restore books to Hive.
  Future<void> restoreBooksToHive(List<Book> books) async {
    final booksBox = Hive.box<BookModel>(booksTrackerBoxName);

    // Clear existing books
    await booksBox.clear();

    // Add restored books
    for (final book in books) {
      final model = BookModel.fromEntity(book);
      await booksBox.put(book.id, model);
    }
  }
}

