import '../../repositories/habit_completion_repository.dart';

/// Use case for deleting a habit completion.
///
/// This use case encapsulates the business logic for deleting a habit
/// completion from the repository. It provides a single point of access
/// for this operation and can be easily tested or modified.
class DeleteCompletion {
  final HabitCompletionRepository repository;

  DeleteCompletion({required this.repository});

  /// Deletes a habit completion by its ID from the repository.
  Future<void> call(String id) async {
    await repository.deleteCompletion(id);
  }
}
