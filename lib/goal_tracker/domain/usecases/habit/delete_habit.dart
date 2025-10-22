import '../../repositories/habit_repository.dart';

/// Use case for deleting a habit.
///
/// This use case encapsulates the business logic for deleting a habit
/// from the repository. It provides a single point of access for this
/// operation and can be easily tested or modified.
class DeleteHabit {
  final HabitRepository repository;

  DeleteHabit({required this.repository});

  /// Deletes a habit by its ID from the repository.
  Future<void> call(String id) async {
    await repository.deleteHabit(id);
  }
}
