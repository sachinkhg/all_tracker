import 'package:hive/hive.dart';
import '../models/journal_entry_model.dart';

/// Abstract data source for local journal entry storage.
abstract class JournalLocalDataSource {
  Future<List<JournalEntryModel>> getEntriesByTripId(String tripId);
  Future<JournalEntryModel?> getEntryById(String id);
  Future<void> createEntry(JournalEntryModel entry);
  Future<void> updateEntry(JournalEntryModel entry);
  Future<void> deleteEntry(String id);
}

/// Hive implementation of JournalLocalDataSource.
class JournalLocalDataSourceImpl implements JournalLocalDataSource {
  final Box<JournalEntryModel> box;

  JournalLocalDataSourceImpl(this.box);

  @override
  Future<void> createEntry(JournalEntryModel entry) async {
    await box.put(entry.id, entry);
  }

  @override
  Future<void> deleteEntry(String id) async {
    await box.delete(id);
  }

  @override
  Future<JournalEntryModel?> getEntryById(String id) async {
    return box.get(id);
  }

  @override
  Future<List<JournalEntryModel>> getEntriesByTripId(String tripId) async {
    return box.values.where((entry) => entry.tripId == tripId).toList();
  }

  @override
  Future<void> updateEntry(JournalEntryModel entry) async {
    await box.put(entry.id, entry);
  }
}

