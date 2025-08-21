import '../../../domain/entities/goal.dart';
import '../../../domain/entities/milestone.dart';

abstract class GoalState {}

class GoalInitial extends GoalState {}

class GoalLoading extends GoalState {}

class GoalLoaded extends GoalState {
  final List<Goal> goals;
  final Map<String, Milestone> allMilestonesMap;
  GoalLoaded(this.goals, this.allMilestonesMap);
}

class GoalDetailsLoaded extends GoalState {
  final Goal? goal; // null if not found
  GoalDetailsLoaded(this.goal);
}

class GoalError extends GoalState {
  final String message;
  GoalError(this.message);
}
