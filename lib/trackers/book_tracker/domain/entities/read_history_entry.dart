import 'package:equatable/equatable.dart';

/// Domain entity representing a single read history entry for a book.
///
/// This entity tracks when a book was started and completed during a specific reading cycle.
/// Used to maintain a history of multiple reads of the same book.
class ReadHistoryEntry extends Equatable {
  /// Date when the reading cycle started (nullable).
  final DateTime? dateStarted;

  /// Date when the reading cycle was completed (nullable).
  final DateTime? dateRead;

  const ReadHistoryEntry({
    this.dateStarted,
    this.dateRead,
  });

  @override
  List<Object?> get props => [dateStarted, dateRead];

  /// Creates a copy of this ReadHistoryEntry with the given fields replaced.
  ReadHistoryEntry copyWith({
    DateTime? dateStarted,
    DateTime? dateRead,
  }) {
    return ReadHistoryEntry(
      dateStarted: dateStarted ?? this.dateStarted,
      dateRead: dateRead ?? this.dateRead,
    );
  }

  /// Returns true if this read entry is completed (has dateRead).
  bool get isCompleted => dateRead != null;
}

