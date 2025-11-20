import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/usecases/journal/create_journal_entry.dart';
import '../../domain/usecases/journal/get_entries_by_trip_id.dart';
import '../../domain/usecases/journal/update_journal_entry.dart';
import '../../domain/usecases/journal/delete_journal_entry.dart';
import 'journal_state.dart';

/// Cubit to manage Journal state.
class JournalCubit extends Cubit<JournalState> {
  final CreateJournalEntry create;
  final GetEntriesByTripId getEntries;
  final UpdateJournalEntry update;
  final DeleteJournalEntry delete;

  static const _uuid = Uuid();

  JournalCubit({
    required this.create,
    required this.getEntries,
    required this.update,
    required this.delete,
  }) : super(JournalLoading());

  Future<void> loadEntries(String tripId) async {
    try {
      emit(JournalLoading());
      final entries = await getEntries(tripId);
      entries.sort((a, b) => b.date.compareTo(a.date)); // Newest first
      emit(JournalLoaded(entries));
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<void> createEntry({
    required String tripId,
    required DateTime date,
    required String content,
  }) async {
    try {
      final now = DateTime.now();
      final entry = JournalEntry(
        id: _uuid.v4(),
        tripId: tripId,
        date: date,
        content: content,
        createdAt: now,
        updatedAt: now,
      );

      await create(entry);
      await loadEntries(tripId);
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<void> updateEntry(JournalEntry entry) async {
    try {
      final updated = JournalEntry(
        id: entry.id,
        tripId: entry.tripId,
        date: entry.date,
        content: entry.content,
        createdAt: entry.createdAt,
        updatedAt: DateTime.now(),
      );

      await update(updated);
      await loadEntries(entry.tripId);
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<void> deleteEntry(String id, String tripId) async {
    try {
      await delete(id);
      await loadEntries(tripId);
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }
}

