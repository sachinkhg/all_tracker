// lib/trackers/book_tracker/core/constants.dart

/// ---------------------------------------------------------------------------
/// Book Tracker Constants
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Constants specific to the book_tracker module.
/// - Module-level box names and configuration values.
///
/// Cross-module guidance:
/// - Do **not** import feature-level constants from other modules to avoid circular dependencies.
/// - Shared constants are re-exported from app_constants.dart if needed.
/// ---------------------------------------------------------------------------

/// Hive box name for book persistence.
///
/// - Keep this name stable across app versions to avoid data loss or migration overhead.
/// - The box name is referenced in both `HiveInitializer` and repository/data source wiring.
const String booksTrackerBoxName = 'books_tracker_box';

