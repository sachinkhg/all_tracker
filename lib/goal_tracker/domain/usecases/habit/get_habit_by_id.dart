import '../../entities/habit.dart';
import '../../repositories/habit_repository.dart';

/// Use case for retrieving a specific habit by ID.
///
/// This use case encapsulates the business logic for fetching a single habit
/// from the repository. It provides a single point of access for this
/// operation and can be easily tested or modified.
class GetHabitById {
  final HabitRepository repository;

  GetHabitById({required this.repository});

  /// Retrieves a habit by its ID from the repository.
  Future<Habit?> call(String id) async {
    return await repository.getHabitById(id);
  }
}
