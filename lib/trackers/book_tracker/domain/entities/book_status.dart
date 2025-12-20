/// Domain enum for book reading status.
///
/// This enum represents the different states a book can be in based on reading progress.
enum BookStatus {
  notStarted,
  reading,
  completed;

  /// Returns a human-readable display name for the book status.
  String get displayName {
    switch (this) {
      case BookStatus.notStarted:
        return 'Not Started';
      case BookStatus.reading:
        return 'Reading';
      case BookStatus.completed:
        return 'Completed';
    }
  }
}

