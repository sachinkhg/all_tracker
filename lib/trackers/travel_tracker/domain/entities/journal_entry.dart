import 'package:equatable/equatable.dart';

/// Domain model for a Journal Entry.
///
/// Represents a daily journal entry for a trip with formatted text content.
class JournalEntry extends Equatable {
  /// Unique identifier for the entry (GUID recommended).
  final String id;

  /// Associated trip ID.
  final String tripId;

  /// Date of the journal entry.
  final DateTime date;

  /// Content of the journal entry (supports basic text formatting).
  final String content;

  /// When the entry was created.
  final DateTime createdAt;

  /// When the entry was last updated.
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.tripId,
    required this.date,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        tripId,
        date,
        content,
        createdAt,
        updatedAt,
      ];
}

