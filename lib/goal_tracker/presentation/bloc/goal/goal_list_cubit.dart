import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/entities/milestone.dart';
import '../../../domain/usecases/goal_usecases.dart';
import '../../../domain/usecases/milestone_usecases.dart';

class GoalListState {
  final bool loading;
  final List<Goal> goals;
  final Map<String, Milestone> allMilestonesMap;
  final String? error;

  const GoalListState({
    this.loading = false,
    this.goals = const [],
    this.allMilestonesMap = const {},
    this.error,
  });

  GoalListState copyWith({
    bool? loading,
    List<Goal>? goals,
    Map<String, Milestone>? allMilestonesMap,
    String? error,
  }) {
    return GoalListState(
      loading: loading ?? this.loading,
      goals: goals ?? this.goals,
      allMilestonesMap: allMilestonesMap ?? this.allMilestonesMap,
      error: error,
    );
  }
}

class GoalListCubit extends Cubit<GoalListState> {
  final GetGoals getGoals;
  final GetMilestonesForGoal getMilestonesForGoal;

  GoalListCubit({
    required this.getGoals,
    required this.getMilestonesForGoal,
  }) : super(const GoalListState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final goals = await getGoals();

      // Build the milestone map for all goals (Option-2 association)
      final Map<String, Milestone> allMap = {};
      for (final g in goals) {
        final ms = await getMilestonesForGoal(g.id);
        for (final m in ms) {
          allMap[m.id] = m;
        }
      }

      emit(state.copyWith(loading: false, goals: goals, allMilestonesMap: allMap));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
