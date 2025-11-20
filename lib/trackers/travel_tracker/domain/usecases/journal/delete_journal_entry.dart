import '../../repositories/journal_repository.dart';

/// Use case for deleting a journal entry.
class DeleteJournalEntry {
  final JournalRepository repository;

  DeleteJournalEntry(this.repository);

  Future<void> call(String id) async => repository.deleteEntry(id);
}

