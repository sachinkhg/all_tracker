import 'package:all_tracker/goal_tracker/domain/repositories/milestone_repository.dart';

import '../entities/goal.dart';
import '../repositories/goal_repository.dart';

// ----------------------
// Get all Goals
// ----------------------
class GetGoals {
  final GoalRepository repository;
  GetGoals(this.repository);

  Future<List<Goal>> call() {
    return repository.getGoals();
  }
}

// ----------------------
// Get Goal by ID
// ----------------------
class GetGoalById {
  final GoalRepository repository;
  GetGoalById(this.repository);

  Future<Goal?> call(String id) {
    return repository.getGoalById(id);
  }
}

// ----------------------
// Add Goal
// ----------------------
class AddGoal {
  final GoalRepository repository;
  AddGoal(this.repository);

  Future<void> call(Goal goal) {
    return repository.addGoal(goal);
  }
}

// ----------------------
// Update Goal
// ----------------------
class UpdateGoal {
  final GoalRepository repository;
  UpdateGoal(this.repository);

  Future<void> call(Goal goal) {
    return repository.updateGoal(goal);
  }
}

// ----------------------
// Delete Goal
// ----------------------
class DeleteGoal {
  final GoalRepository repository;
  DeleteGoal(this.repository);

  Future<void> call(String id) {
    return repository.deleteGoal(id);
  }
}

// ----------------------
// Clear All Goals
// ----------------------
class ClearAllGoals {
  final GoalRepository repository;
  ClearAllGoals(this.repository);

  Future<void> call() {
    return repository.clearAll();
  }
}
