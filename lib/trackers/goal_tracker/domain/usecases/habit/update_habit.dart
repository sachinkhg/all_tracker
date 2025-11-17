import '../../entities/habit.dart';
import '../../repositories/habit_repository.dart';

/// Use case for updating an existing habit.
///
/// This use case encapsulates the business logic for updating a habit
/// in the repository. It provides a single point of access for this
/// operation and can be easily tested or modified.
class UpdateHabit {
  final HabitRepository repository;

  UpdateHabit({required this.repository});

  /// Updates an existing habit in the repository.
  Future<void> call(Habit habit) async {
    await repository.updateHabit(habit);
  }
}
