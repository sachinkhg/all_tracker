import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/goal_usecases.dart';
import '../../../domain/usecases/milestone_usecases.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {

  final GetGoals getGoals;
  final GetGoalById getGoalById;
  final AddGoal addGoal;
  final UpdateGoal updateGoal;
  final DeleteGoal deleteGoal;
  final ClearAllGoals clearAllGoals;
  final GetMilestones getAllMilestones;
  final DeleteMilestone deleteMilestone;


    GoalBloc({
    required this.getGoals,
    required this.getGoalById,
    required this.addGoal,
    required this.updateGoal,
    required this.deleteGoal,
    required this.clearAllGoals,
    required this.getAllMilestones, 
    required this.deleteMilestone, // <-- Add deleteMilestone here
    // <-- And in constructor
  }) : super(GoalInitial()) {
    on<LoadGoals>(_onLoadGoals);
    on<GetGoalDetails>(_onGetGoalDetails);
    on<AddGoalEvent>(_onAddGoal);
    on<UpdateGoalEvent>(_onUpdateGoal);
    on<DeleteGoalEvent>(_onDeleteGoal);
    on<ClearAllGoalsEvent>(_onClearAllGoals);
    on<DeleteGoalAndMilestonesEvent>(_onDeleteGoalAndMilestones);
  }

    Future<void> _onLoadGoals(LoadGoals event, Emitter<GoalState> emit) async {
      emit(GoalLoading());
      try {
        final goals = await getGoals();
        final allMilestonesList = await getAllMilestones(); // <-- Fetch all milestones
        final allMilestonesMap = { for (var m in allMilestonesList) m.id : m };
        emit(GoalLoaded(goals, allMilestonesMap));
      } catch (e) {
        emit(GoalError(e.toString()));
      }
    }

  Future<void> _onGetGoalDetails(GetGoalDetails event, Emitter<GoalState> emit) async {
    emit(GoalLoading());
    try {
      final goal = await getGoalById(event.id);
      emit(GoalDetailsLoaded(goal));
    } catch (e) {
      emit(GoalError(e.toString()));
    }
  }

  Future<void> _onAddGoal(AddGoalEvent event, Emitter<GoalState> emit) async {
    try {
      await addGoal(event.goal);
      add(LoadGoals()); // refresh list
    } catch (e) {
      emit(GoalError(e.toString()));
    }
  }

  Future<void> _onUpdateGoal(UpdateGoalEvent event, Emitter<GoalState> emit) async {
    try {
      await updateGoal(event.goal);
      add(LoadGoals()); // refresh list
    } catch (e) {
      emit(GoalError(e.toString()));
    }
  }

  Future<void> _onDeleteGoal(DeleteGoalEvent event, Emitter<GoalState> emit) async {
    try {
      await deleteGoal(event.id);
      add(LoadGoals()); // refresh list
    } catch (e) {
      emit(GoalError(e.toString()));
    }
  }

  Future<void> _onClearAllGoals(ClearAllGoalsEvent event, Emitter<GoalState> emit) async {
    try {
      await clearAllGoals();
      add(LoadGoals());
    } catch (e) {
      emit(GoalError(e.toString()));
    }
  }

Future _onDeleteGoalAndMilestones(
  DeleteGoalAndMilestonesEvent event,
  Emitter<GoalState> emit,
) async {
  try {
    emit(GoalLoading());

    // You need a Milestone delete use case injected, e.g. deleteMilestone
    for (final milestoneId in event.milestoneIds) {
      await deleteMilestone(milestoneId);
    }
    await deleteGoal(event.goalId);
    add(LoadGoals());
  } catch (e) {
    emit(GoalError(e.toString()));
  }
}
}