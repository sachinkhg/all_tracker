import '../entities/journal_entry.dart';

/// Abstract repository defining CRUD operations for [JournalEntry] entities.
abstract class JournalRepository {
  /// Get all journal entries for a trip.
  Future<List<JournalEntry>> getEntriesByTripId(String tripId);

  /// Get an entry by ID.
  Future<JournalEntry?> getEntryById(String id);

  /// Create a new journal entry.
  /// Returns the created entry.
  Future<JournalEntry> createEntry(JournalEntry entry);

  /// Update an existing journal entry.
  Future<void> updateEntry(JournalEntry entry);

  /// Delete a journal entry.
  Future<void> deleteEntry(String id);
}

