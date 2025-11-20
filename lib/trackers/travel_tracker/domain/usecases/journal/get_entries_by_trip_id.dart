import '../../entities/journal_entry.dart';
import '../../repositories/journal_repository.dart';

/// Use case for retrieving all journal entries for a trip.
class GetEntriesByTripId {
  final JournalRepository repository;

  GetEntriesByTripId(this.repository);

  Future<List<JournalEntry>> call(String tripId) async => repository.getEntriesByTripId(tripId);
}

