import '../../entities/habit_completion.dart';
import '../../repositories/habit_completion_repository.dart';

/// Use case for creating a new habit completion.
///
/// This use case encapsulates the business logic for creating a new habit
/// completion in the repository. It provides a single point of access for
/// this operation and can be easily tested or modified.
class CreateCompletion {
  final HabitCompletionRepository repository;

  CreateCompletion({required this.repository});

  /// Creates a new habit completion in the repository.
  Future<void> call(HabitCompletion completion) async {
    await repository.createCompletion(completion);
  }
}
