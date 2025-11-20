import '../../entities/journal_entry.dart';
import '../../repositories/journal_repository.dart';

/// Use case for creating a journal entry.
class CreateJournalEntry {
  final JournalRepository repository;

  CreateJournalEntry(this.repository);

  Future<void> call(JournalEntry entry) async => repository.createEntry(entry);
}

