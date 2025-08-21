import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/goal_usecases.dart';
import '../../domain/usecases/milestone_usecases.dart';
import 'goal/goal_bloc.dart';
import 'goal/goal_event.dart';
import 'milestone/milestone_bloc.dart';

class BlocServiceProvider extends StatelessWidget {
  final Widget child;

  // Dependencies for GoalBloc
  final GetGoals getGoals;
  final GetGoalById getGoalById;
  final AddGoal addGoal;
  final UpdateGoal updateGoal;
  final DeleteGoal deleteGoal;
  final ClearAllGoals clearAllGoals;

  // Dependencies for MilestoneBloc
  final GetMilestones getMilestones;
  final GetMilestoneById getMilestoneById;
  final AddMilestone addMilestone;
  final UpdateMilestone updateMilestone;
  final DeleteMilestone deleteMilestone;
  final ClearAllMilestones clearAllMilestones;

  const BlocServiceProvider({
    super.key,
    required this.child,
    required this.getGoals,
    required this.getGoalById,
    required this.addGoal,
    required this.updateGoal,
    required this.deleteGoal,
    required this.clearAllGoals,
    required this.getMilestones,
    required this.getMilestoneById,
    required this.addMilestone,
    required this.updateMilestone,
    required this.deleteMilestone,
    required this.clearAllMilestones,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GoalBloc>(
          create: (_) => GoalBloc(
            getGoals: getGoals,
            getGoalById: getGoalById,
            addGoal: addGoal,
            updateGoal: updateGoal,
            deleteGoal: deleteGoal,
            clearAllGoals: clearAllGoals,
            getAllMilestones: getMilestones,
            deleteMilestone: deleteMilestone, // <-- Pass the usecase
          )..add(LoadGoals()),  // Dispatch LoadGoals event on creation
        ),
        BlocProvider<MilestoneBloc>(
          create: (_) => MilestoneBloc(
            getMilestones: getMilestones,
            getMilestoneById: getMilestoneById,
            addMilestone: addMilestone,
            updateMilestone: updateMilestone,
            deleteMilestone: deleteMilestone,
            clearAllMilestones: clearAllMilestones,
          ),
        ),
      ],
      child: child,
    );
  }
}

