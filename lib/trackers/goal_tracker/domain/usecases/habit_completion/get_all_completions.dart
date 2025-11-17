import '../../entities/habit_completion.dart';
import '../../repositories/habit_completion_repository.dart';

/// Use case for retrieving all habit completions.
///
/// This use case encapsulates the business logic for fetching all habit
/// completions from the repository. It provides a single point of access
/// for this operation and can be easily tested or modified.
class GetAllCompletions {
  final HabitCompletionRepository repository;

  GetAllCompletions({required this.repository});

  /// Retrieves all habit completions from the repository.
  Future<List<HabitCompletion>> call() async {
    return await repository.getAllCompletions();
  }
}
