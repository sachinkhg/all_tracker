import '../../entities/habit.dart';
import '../../repositories/habit_repository.dart';

/// Use case for creating a new habit.
///
/// This use case encapsulates the business logic for creating a new habit
/// in the repository. It provides a single point of access for this
/// operation and can be easily tested or modified.
class CreateHabit {
  final HabitRepository repository;

  CreateHabit({required this.repository});

  /// Creates a new habit in the repository.
  Future<void> call(Habit habit) async {
    await repository.createHabit(habit);
  }
}
