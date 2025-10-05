import 'package:equatable/equatable.dart';
import '../../domain/entities/goal.dart';


// Base state for goal operations
abstract class GoalState extends Equatable {
const GoalState();
@override
List<Object?> get props => [];
}


// Loading state
class GoalsLoading extends GoalState {}


// Loaded state with list of goals
class GoalsLoaded extends GoalState {
final List<Goal> goals;
const GoalsLoaded(this.goals);
@override
List<Object?> get props => [goals];
}


// Error state
class GoalsError extends GoalState {
final String message;
const GoalsError(this.message);
@override
List<Object?> get props => [message];
}