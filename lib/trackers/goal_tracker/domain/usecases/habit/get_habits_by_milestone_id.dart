import '../../entities/habit.dart';
import '../../repositories/habit_repository.dart';

/// Use case for retrieving habits associated with a specific milestone.
///
/// This use case encapsulates the business logic for fetching habits
/// that belong to a particular milestone. It provides a single point
/// of access for this operation and can be easily tested or modified.
class GetHabitsByMilestoneId {
  final HabitRepository repository;

  GetHabitsByMilestoneId({required this.repository});

  /// Retrieves all habits associated with the specified milestone.
  Future<List<Habit>> call(String milestoneId) async {
    return await repository.getHabitsByMilestoneId(milestoneId);
  }
}
