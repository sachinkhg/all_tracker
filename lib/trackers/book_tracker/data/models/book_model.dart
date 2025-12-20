import 'package:hive/hive.dart';
import '../../domain/entities/book.dart';
import 'read_history_entry_model.dart';

part 'book_model.g.dart'; // Generated via build_runner

/// ---------------------------------------------------------------------------
/// BookModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Represents a persisted `Book` entity within Hive.
/// - Acts as a bridge between domain-layer entities and Hive storage.
///
/// Schema & Migration Guidelines:
/// - Each `@HiveField` index is permanent once written to storage.
/// - Never reuse or reorder field numbers — doing so will corrupt persisted data.
/// - Add new fields only at the end with new, unique field numbers.
/// - Document any changes in `migration_notes.md`.
///
/// TypeId: 32 (as documented in migration_notes.md)
/// ---------------------------------------------------------------------------

@HiveType(typeId: 32)
class BookModel extends HiveObject {
  /// Unique identifier for the book.
  ///
  /// Hive field number **0** — stable ID, never change or reuse.
  @HiveField(0)
  String id;

  /// Title of the book.
  ///
  /// Hive field number **1** — required.
  @HiveField(1)
  String title;

  /// Primary author of the book.
  ///
  /// Hive field number **2** — required.
  @HiveField(2)
  String primaryAuthor;

  /// Number of pages in the book.
  ///
  /// Hive field number **3** — required.
  @HiveField(3)
  int pageCount;

  /// Average rating for the book (0-5 if present).
  ///
  /// Hive field number **4** — nullable.
  @HiveField(4)
  double? avgRating;

  /// Publication date of the book.
  ///
  /// Hive field number **5** — nullable.
  @HiveField(5)
  DateTime? datePublished;

  /// Date when the current reading cycle started.
  ///
  /// Hive field number **6** — nullable.
  @HiveField(6)
  DateTime? dateStarted;

  /// Date when the current reading cycle was completed.
  ///
  /// Hive field number **7** — nullable.
  @HiveField(7)
  DateTime? dateRead;

  /// History of previous reading cycles.
  ///
  /// Hive field number **8** — nullable, defaults to empty list for backward compatibility.
  @HiveField(8)
  List<ReadHistoryEntryModel>? readHistory;

  /// Timestamp of creation.
  ///
  /// Hive field number **9** — required.
  @HiveField(9)
  DateTime createdAt;

  /// Timestamp of last update.
  ///
  /// Hive field number **10** — required.
  @HiveField(10)
  DateTime updatedAt;

  BookModel({
    required this.id,
    required this.title,
    required this.primaryAuthor,
    required this.pageCount,
    this.avgRating,
    this.datePublished,
    this.dateStarted,
    this.dateRead,
    List<ReadHistoryEntryModel>? readHistory,
    required this.createdAt,
    required this.updatedAt,
  }) : readHistory = readHistory ?? [];

  /// Factory constructor to build a [BookModel] from a domain [Book].
  factory BookModel.fromEntity(Book book) => BookModel(
        id: book.id,
        title: book.title,
        primaryAuthor: book.primaryAuthor,
        pageCount: book.pageCount,
        avgRating: book.avgRating,
        datePublished: book.datePublished,
        dateStarted: book.dateStarted,
        dateRead: book.dateRead,
        readHistory: book.readHistory
            .map((entry) => ReadHistoryEntryModel.fromEntity(entry))
            .toList(),
        createdAt: book.createdAt,
        updatedAt: book.updatedAt,
      );

  /// Converts this model back into a domain [Book] entity.
  Book toEntity() {
    // Handle backward compatibility: if readHistory is null or empty,
    // treat it as an empty list
    final history = readHistory ?? [];
    final readHistoryEntries = history.map((model) => model.toEntity()).toList();

    return Book(
      id: id,
      title: title,
      primaryAuthor: primaryAuthor,
      pageCount: pageCount,
      avgRating: avgRating,
      datePublished: datePublished,
      dateStarted: dateStarted,
      dateRead: dateRead,
      readHistory: readHistoryEntries,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates a copy of this BookModel with the given fields replaced.
  BookModel copyWith({
    String? id,
    String? title,
    String? primaryAuthor,
    int? pageCount,
    double? avgRating,
    DateTime? datePublished,
    DateTime? dateStarted,
    DateTime? dateRead,
    List<ReadHistoryEntryModel>? readHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      primaryAuthor: primaryAuthor ?? this.primaryAuthor,
      pageCount: pageCount ?? this.pageCount,
      avgRating: avgRating ?? this.avgRating,
      datePublished: datePublished ?? this.datePublished,
      dateStarted: dateStarted ?? this.dateStarted,
      dateRead: dateRead ?? this.dateRead,
      readHistory: readHistory ?? this.readHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

