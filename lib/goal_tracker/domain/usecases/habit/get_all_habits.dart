import '../../entities/habit.dart';
import '../../repositories/habit_repository.dart';

/// Use case for retrieving all habits.
///
/// This use case encapsulates the business logic for fetching all habits
/// from the repository. It provides a single point of access for this
/// operation and can be easily tested or modified.
class GetAllHabits {
  final HabitRepository repository;

  GetAllHabits({required this.repository});

  /// Retrieves all habits from the repository.
  Future<List<Habit>> call() async {
    return await repository.getAllHabits();
  }
}
