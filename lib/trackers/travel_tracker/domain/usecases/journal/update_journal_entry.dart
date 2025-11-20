import '../../entities/journal_entry.dart';
import '../../repositories/journal_repository.dart';

/// Use case for updating a journal entry.
class UpdateJournalEntry {
  final JournalRepository repository;

  UpdateJournalEntry(this.repository);

  Future<void> call(JournalEntry entry) async => repository.updateEntry(entry);
}

