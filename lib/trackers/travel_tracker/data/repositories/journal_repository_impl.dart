import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_local_data_source.dart';
import '../models/journal_entry_model.dart';

/// Concrete implementation of JournalRepository.
class JournalRepositoryImpl implements JournalRepository {
  final JournalLocalDataSource local;

  JournalRepositoryImpl(this.local);

  @override
  Future<void> createEntry(JournalEntry entry) async {
    final model = JournalEntryModel.fromEntity(entry);
    await local.createEntry(model);
  }

  @override
  Future<void> deleteEntry(String id) async {
    await local.deleteEntry(id);
  }

  @override
  Future<JournalEntry?> getEntryById(String id) async {
    final model = await local.getEntryById(id);
    return model?.toEntity();
  }

  @override
  Future<List<JournalEntry>> getEntriesByTripId(String tripId) async {
    final models = await local.getEntriesByTripId(tripId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updateEntry(JournalEntry entry) async {
    final model = JournalEntryModel.fromEntity(entry);
    await local.updateEntry(model);
  }
}

