/*
 * File: ./lib/trackers/book_tracker/domain/entities/book.dart
 *
 * Purpose:
 *   Domain representation of a Book used throughout the application business logic.
 *   This file defines the plain domain entity (immutable, equatable) and documents
 *   how it maps to persistence DTOs / Hive models (those mapper functions live in
 *   the data layer / local datasource).
 *
 * Serialization rules (for implementers of DTO / Hive adapters):
 *   - `id` (String)         : non-nullable, unique identifier (GUID-like). Expected to be persisted.
 *   - `title` (String)      : non-nullable, title of the book.
 *   - `primaryAuthor` (String): non-nullable, primary author of the book.
 *   - `pageCount` (int)     : non-nullable, number of pages (must be > 0).
 *   - `selfRating` (double?) : nullable, self rating (0-5 if present).
 *   - `datePublished` (DateTime?): nullable, publication date.
 *   - `dateStarted` (DateTime?): nullable, date when current reading cycle started.
 *   - `dateRead` (DateTime?): nullable, date when current reading cycle completed.
 *   - `readHistory` (List<ReadHistoryEntry>): nullable, history of previous reads (defaults to empty).
 *   - `createdAt` (DateTime): non-nullable, timestamp of creation.
 *   - `updatedAt` (DateTime): non-nullable, timestamp of last update.
 *
 * Compatibility guidance:
 *   - When adding/removing persisted fields, DO NOT reuse Hive field numbers previously used.
 *   - Any change to persisted shape or Hive field numbers must be recorded in migration_notes.md
 *     and corresponding migration code must be added to the local data source.
 *   - Mapper helpers (e.g., BookModel.fromEntity(), BookModel.toEntity()) should explicitly handle
 *     legacy values (for instance missing fields => default to appropriate values).
 *
 * Notes for implementers:
 *   - This file intentionally contains only the pure domain entity and no persistence annotations.
 *     Keep persistence concerns (Hive annotations, adapters) inside the data layer to avoid
 *     coupling the domain layer to a storage implementation.
 */

import 'package:equatable/equatable.dart';
import 'read_history_entry.dart';
import 'book_status.dart';

/// Domain model for a Book.
///
/// This class is intended for use inside the domain and presentation layers only.
/// Persistence-specific mapping (Hive fields, DTO serialization) should live in the
/// data/local layer (e.g., `book_model.dart`) which converts
/// between this entity and the stored representation.
class Book extends Equatable {
  /// Unique identifier for the book (GUID recommended).
  ///
  /// Persistence hint: typically stored as the primary id in the DTO.
  /// Expected Hive field number (data layer): 0.
  final String id;

  /// Title of the book.
  ///
  /// Persistence hint: non-nullable in domain; user-provided title.
  /// Expected Hive field number (data layer): 1.
  final String title;

  /// Primary author of the book.
  ///
  /// Persistence hint: non-nullable in domain; user-provided author name.
  /// Expected Hive field number (data layer): 2.
  final String primaryAuthor;

  /// Number of pages in the book.
  ///
  /// Persistence hint: non-nullable in domain; must be > 0.
  /// Expected Hive field number (data layer): 3.
  final int pageCount;

  /// Self rating for the book (0-5 if present).
  ///
  /// Persistence hint: nullable in domain; optional self rating value.
  /// Expected Hive field number (data layer): 11.
  final double? selfRating;

  /// Publication date of the book.
  ///
  /// Persistence hint: nullable in domain; optional publication date.
  /// Expected Hive field number (data layer): 5.
  final DateTime? datePublished;

  /// Date when the current reading cycle started.
  ///
  /// Persistence hint: nullable in domain; represents the start of the latest read.
  /// Expected Hive field number (data layer): 6.
  final DateTime? dateStarted;

  /// Date when the current reading cycle was completed.
  ///
  /// Persistence hint: nullable in domain; represents the completion of the latest read.
  /// Expected Hive field number (data layer): 7.
  final DateTime? dateRead;

  /// History of previous reading cycles.
  ///
  /// Persistence hint: nullable in domain; defaults to empty list for backward compatibility.
  /// Expected Hive field number (data layer): 8.
  final List<ReadHistoryEntry> readHistory;

  /// Timestamp of creation.
  ///
  /// Persistence hint: non-nullable in domain; represents when the book was created.
  /// Expected Hive field number (data layer): 9.
  final DateTime createdAt;

  /// Timestamp of last update.
  ///
  /// Persistence hint: non-nullable in domain; represents when the book was last modified.
  /// Expected Hive field number (data layer): 10.
  final DateTime updatedAt;

  /// Domain constructor.
  ///
  /// Keep this immutable so instances can be compared and used in const contexts.
  const Book({
    required this.id,
    required this.title,
    required this.primaryAuthor,
    required this.pageCount,
    this.selfRating,
    this.datePublished,
    this.dateStarted,
    this.dateRead,
    List<ReadHistoryEntry>? readHistory,
    required this.createdAt,
    required this.updatedAt,
  }) : readHistory = readHistory ?? const [];

  @override
  List<Object?> get props => [
        id,
        title,
        primaryAuthor,
        pageCount,
        selfRating,
        datePublished,
        dateStarted,
        dateRead,
        readHistory,
        createdAt,
        updatedAt,
      ];

  /// Creates a copy of this Book with the given fields replaced.
  ///
  /// Useful for updates where only certain fields change.
  Book copyWith({
    String? id,
    String? title,
    String? primaryAuthor,
    int? pageCount,
    double? selfRating,
    DateTime? datePublished,
    DateTime? dateStarted,
    DateTime? dateRead,
    List<ReadHistoryEntry>? readHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      primaryAuthor: primaryAuthor ?? this.primaryAuthor,
      pageCount: pageCount ?? this.pageCount,
      selfRating: selfRating ?? this.selfRating,
      datePublished: datePublished ?? this.datePublished,
      dateStarted: dateStarted ?? this.dateStarted,
      dateRead: dateRead ?? this.dateRead,
      readHistory: readHistory ?? this.readHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns the current reading status based on dateStarted and dateRead.
  ///
  /// - notStarted: no dateStarted
  /// - reading: dateStarted present AND dateRead null
  /// - completed: dateRead present
  BookStatus get status {
    if (dateRead != null) {
      return BookStatus.completed;
    } else if (dateStarted != null) {
      return BookStatus.reading;
    } else {
      return BookStatus.notStarted;
    }
  }

  /// Returns the reading duration in days for the current read (only if both dates exist).
  ///
  /// Returns null if either dateStarted or dateRead is missing.
  int? get readingDurationDays {
    if (dateStarted != null && dateRead != null) {
      return dateRead!.difference(dateStarted!).inDays;
    }
    return null;
  }

  /// Returns pages per day for the current read (only if valid duration exists).
  ///
  /// Returns null if readingDurationDays is null or 0.
  double? get pagesPerDay {
    final duration = readingDurationDays;
    if (duration != null && duration > 0 && pageCount > 0) {
      return pageCount / duration;
    }
    return null;
  }

  /// Returns the total number of completed reads (history + current if completed).
  int get totalCompletedReads {
    int count = readHistory.where((entry) => entry.isCompleted).length;
    if (dateRead != null) {
      count += 1; // Current read is completed
    }
    return count;
  }
}

