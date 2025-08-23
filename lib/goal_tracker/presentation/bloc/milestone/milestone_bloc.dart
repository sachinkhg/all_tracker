import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/usecases/milestone_usecases.dart';
import 'milestone_event.dart';
import 'milestone_state.dart';

class MilestoneBloc extends Bloc<MilestoneEvent, MilestoneState> {
  final GetMilestones getMilestones;
  final GetMilestoneById getMilestoneById;
  final AddMilestone addMilestone;
  final UpdateMilestone updateMilestone;
  final DeleteMilestone deleteMilestone;
  final ClearAllMilestones clearAllMilestones;
  final GetMilestonesForGoal getMilestonesForGoal;

  MilestoneBloc({
    required this.getMilestones,
    required this.getMilestoneById,
    required this.addMilestone,
    required this.updateMilestone,
    required this.deleteMilestone,
    required this.clearAllMilestones,
    required this.getMilestonesForGoal,
  }) : super(MilestoneInitial()) {
    on<LoadMilestones>(_onLoadMilestones);
    on<GetMilestoneDetails>(_onGetMilestoneDetails);
    on<AddMilestoneEvent>(_onAddMilestone);
    on<UpdateMilestoneEvent>(_onUpdateMilestone);
    on<DeleteMilestoneEvent>(_onDeleteMilestone);
    on<ClearAllMilestonesEvent>(_onClearAllMilestones);
  }

  Future<void> _onLoadMilestones(LoadMilestones event, Emitter<MilestoneState> emit) async {
    emit(MilestoneLoading());
    try {
      final milestones = await getMilestones();
      emit(MilestoneLoaded(milestones));
    } catch (e) {
      emit(MilestoneError(e.toString()));
    }
  }


  Future<void> _onGetMilestoneDetails(GetMilestoneDetails event, Emitter<MilestoneState> emit) async {
    emit(MilestoneLoading());
    try {
      final milestone = await getMilestoneById(event.id);
      emit(MilestoneDetailsLoaded(milestone));
    } catch (e) {
      emit(MilestoneError(e.toString()));
    }
  }

  Future<void> _onAddMilestone(AddMilestoneEvent event, Emitter<MilestoneState> emit) async {
    try {
      await addMilestone(event.milestone);
      add(LoadMilestones()); // refresh list
    } catch (e) {
      emit(MilestoneError(e.toString()));
    }
  }

  Future<void> _onUpdateMilestone(UpdateMilestoneEvent event, Emitter<MilestoneState> emit) async {
    try {
      await updateMilestone(event.milestone);
      add(LoadMilestones()); // refresh list
    } catch (e) {
      emit(MilestoneError(e.toString()));
    }
  }

  Future<void> _onDeleteMilestone(DeleteMilestoneEvent event, Emitter<MilestoneState> emit) async {
    try {
      await deleteMilestone(event.id);
      add(LoadMilestones()); // refresh list
    } catch (e) {
      emit(MilestoneError(e.toString()));
    }
  }

  Future<void> _onClearAllMilestones(ClearAllMilestonesEvent event, Emitter<MilestoneState> emit) async {
    try {
      await clearAllMilestones();
      add(LoadMilestones());
    } catch (e) {
      emit(MilestoneError(e.toString()));
    }
  }
}
