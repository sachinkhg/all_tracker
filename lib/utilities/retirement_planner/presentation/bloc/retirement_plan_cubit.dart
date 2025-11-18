import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/retirement_plan.dart';
import '../../domain/usecases/plan/create_plan.dart';
import '../../domain/usecases/plan/get_all_plans.dart';
import '../../domain/usecases/plan/get_plan_by_id.dart';
import '../../domain/usecases/plan/update_plan.dart';
import '../../domain/usecases/plan/delete_plan.dart';
import '../../domain/usecases/plan/calculate_retirement_plan.dart';
import 'retirement_plan_state.dart';

/// Cubit to manage RetirementPlan state
class RetirementPlanCubit extends Cubit<RetirementPlanState> {
  final GetAllPlans getAllPlans;
  final GetPlanById getPlanById;
  final CreatePlan createPlan;
  final UpdatePlan updatePlan;
  final DeletePlan deletePlan;
  final CalculateRetirementPlan calculateRetirementPlan;

  RetirementPlanCubit({
    required this.getAllPlans,
    required this.getPlanById,
    required this.createPlan,
    required this.updatePlan,
    required this.deletePlan,
    required this.calculateRetirementPlan,
  }) : super(PlansLoading()) {
    loadPlans();
  }

  Future<void> loadPlans() async {
    try {
      emit(PlansLoading());
      final plans = await getAllPlans();
      emit(PlansLoaded(plans));
    } catch (e) {
      emit(PlansError(e.toString()));
    }
  }

  Future<RetirementPlan?> loadPlanById(String id) async {
    try {
      emit(PlansLoading());
      final plan = await getPlanById(id);
      if (plan != null) {
        emit(PlanDetailLoaded(plan));
        return plan;
      } else {
        emit(PlanDetailError('Plan not found'));
        return null;
      }
    } catch (e) {
      emit(PlanDetailError(e.toString()));
      return null;
    }
  }

  Future<RetirementPlan?> savePlan(RetirementPlan plan) async {
    try {
      final calculatedPlan = calculateRetirementPlan(plan);
      final now = DateTime.now();
      
      // Check if plan already exists in database
      final existingPlan = plan.id.isNotEmpty 
          ? await getPlanById(plan.id) 
          : null;
      
      if (existingPlan == null) {
        // New plan - generate ID
        final newPlan = calculatedPlan.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          createdAt: now,
          updatedAt: now,
        );
        await createPlan(newPlan);
        await loadPlans();
        return newPlan;
      } else {
        // Existing plan - update
        final planToSave = calculatedPlan.copyWith(
          updatedAt: now,
        );
        await updatePlan(planToSave);
        await loadPlans();
        return planToSave;
      }
    } catch (e) {
      emit(PlansError(e.toString()));
      return null;
    }
  }

  Future<void> deletePlanById(String id) async {
    try {
      await deletePlan(id);
      await loadPlans();
    } catch (e) {
      emit(PlansError(e.toString()));
    }
  }

  /// Calculate retirement plan metrics without saving
  RetirementPlan? calculatePlan(RetirementPlan plan) {
    try {
      return calculateRetirementPlan(plan);
    } catch (e) {
      emit(PlansError(e.toString()));
      return null;
    }
  }
}

