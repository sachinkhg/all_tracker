import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/milestone.dart';
import '../../../domain/usecases/milestone_usecases.dart';

class MilestoneListState {
  final bool loading;
  final List<Milestone> milestones;
  final String? error;

  const MilestoneListState({
    this.loading = false,
    this.milestones = const [],
    this.error,
  });

  MilestoneListState copyWith({
    bool? loading,
    List<Milestone>? milestones,
    String? error,
  }) {
    return MilestoneListState(
      loading: loading ?? this.loading,
      milestones: milestones ?? this.milestones,
      error: error,
    );
  }
}

class MilestoneListCubit extends Cubit<MilestoneListState> {
  final String goalId;
  final GetMilestonesForGoal getMilestonesForGoal;
  final AddMilestone addMilestone;
  final UpdateMilestone updateMilestone;
  final DeleteMilestone deleteMilestone;

  MilestoneListCubit({
    required this.goalId,
    required this.getMilestonesForGoal,
    required this.addMilestone,
    required this.updateMilestone,
    required this.deleteMilestone,
  }) : super(const MilestoneListState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final ms = await getMilestonesForGoal(goalId);
      emit(state.copyWith(loading: false, milestones: ms));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addOne(Milestone m) async {
    await addMilestone(m);
    await load();
  }

  Future<void> updateOne(Milestone m) async {
    await updateMilestone(m);
    await load();
  }

  Future<void> deleteOne(String id) async {
    await deleteMilestone(id);
    await load();
  }
}
