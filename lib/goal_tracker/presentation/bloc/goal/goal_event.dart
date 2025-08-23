// goal_event.dart
import '../../../domain/entities/goal.dart';

abstract class GoalEvent {}

class LoadGoals extends GoalEvent {}

class GetGoalDetails extends GoalEvent {
  final String id;
  GetGoalDetails(this.id);
}

class AddGoalEvent extends GoalEvent {
  final Goal goal;
  AddGoalEvent(this.goal);
}

class UpdateGoalEvent extends GoalEvent {
  final Goal goal;
  UpdateGoalEvent(this.goal);
}

class DeleteGoalEvent extends GoalEvent {
  final String id;
  DeleteGoalEvent(this.id);
}

class ClearAllGoalsEvent extends GoalEvent {}

class DeleteGoalAndMilestonesEvent extends GoalEvent {
  final String goalId;               // <-- only goalId
  DeleteGoalAndMilestonesEvent(this.goalId);
}
