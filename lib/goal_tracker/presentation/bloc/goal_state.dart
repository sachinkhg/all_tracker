import '../../domain/entities/goal.dart';

abstract class GoalState {}

class GoalInitial extends GoalState {}

class GoalLoading extends GoalState {}

class GoalLoaded extends GoalState {
  final List<Goal> goals;
  GoalLoaded(this.goals);
}

class GoalDetailsLoaded extends GoalState {
  final Goal? goal; // null if not found
  GoalDetailsLoaded(this.goal);
}

class GoalError extends GoalState {
  final String message;
  GoalError(this.message);
}
