import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/investment_plan.dart';
import '../../domain/entities/plan_status.dart';
import '../../domain/entities/income_entry.dart';
import '../../domain/entities/expense_entry.dart';
import '../../domain/entities/component_allocation.dart';
import '../../domain/usecases/plan/create_plan.dart';
import '../../domain/usecases/plan/get_all_plans.dart';
import '../../domain/usecases/plan/get_plan_by_id.dart';
import '../../domain/usecases/plan/update_plan.dart';
import '../../domain/usecases/plan/delete_plan.dart';
import '../../domain/usecases/plan/calculate_allocations.dart';
import 'investment_plan_state.dart';

/// Cubit to manage InvestmentPlan state
class InvestmentPlanCubit extends Cubit<InvestmentPlanState> {
  final GetAllPlans getAllPlans;
  final GetPlanById getPlanById;
  final CreatePlan createPlan;
  final UpdatePlan updatePlan;
  final DeletePlan deletePlan;
  final CalculateAllocations calculateAllocations;

  InvestmentPlanCubit({
    required this.getAllPlans,
    required this.getPlanById,
    required this.createPlan,
    required this.updatePlan,
    required this.deletePlan,
    required this.calculateAllocations,
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

  Future<InvestmentPlan?> loadPlanById(String id) async {
    try {
      return await getPlanById(id);
    } catch (e) {
      emit(PlansError(e.toString()));
      return null;
    }
  }

  Future<InvestmentPlan?> savePlan({
    required String name,
    required List<IncomeEntry> incomeEntries,
    required List<ExpenseEntry> expenseEntries,
    String? planId,
  }) async {
    try {
      final now = DateTime.now();
      final allocationsResult = await _calculateAllocationsForPlan(
        incomeEntries,
        expenseEntries,
      );

      // Preserve existing status, duration, and period when updating, default to draft for new plans
      PlanStatus status = PlanStatus.draft;
      String duration = 'Monthly'; // Default value
      String period = ''; // Default empty value
      DateTime? originalCreatedAt;
      if (planId != null) {
        final existingPlan = await getPlanById(planId);
        if (existingPlan != null) {
          status = existingPlan.status;
          duration = existingPlan.duration;
          period = existingPlan.period;
          originalCreatedAt = existingPlan.createdAt;
        }
      }

      final plan = InvestmentPlan(
        id: planId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        duration: duration,
        period: period,
        status: status,
        incomeEntries: incomeEntries,
        expenseEntries: expenseEntries,
        allocations: allocationsResult['allocations'] as List<ComponentAllocation>,
        createdAt: originalCreatedAt ?? now,
        updatedAt: now,
      );

      if (planId != null) {
        await updatePlan(plan);
      } else {
        await createPlan(plan);
      }
      await loadPlans();
      return plan;
    } catch (e) {
      emit(PlansError(e.toString()));
      return null;
    }
  }

  /// Updates the status of a plan with strict workflow validation
  /// Only allows transitions: Draft → Approved → Executed
  Future<bool> updatePlanStatus(String planId, PlanStatus newStatus) async {
    try {
      final plan = await getPlanById(planId);
      if (plan == null) {
        emit(PlansError('Plan not found'));
        return false;
      }

      // Validate status transition (strict workflow)
      final currentStatus = plan.status;
      bool isValidTransition = false;
      
      if (currentStatus == PlanStatus.draft && newStatus == PlanStatus.approved) {
        isValidTransition = true;
      } else if (currentStatus == PlanStatus.approved && newStatus == PlanStatus.executed) {
        isValidTransition = true;
      } else if (currentStatus == newStatus) {
        // Same status is allowed (idempotent)
        isValidTransition = true;
      }

      if (!isValidTransition) {
        emit(PlansError('Invalid status transition: ${currentStatus.displayName} → ${newStatus.displayName}'));
        return false;
      }

      // Update plan with new status
      final updatedPlan = plan.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await updatePlan(updatedPlan);
      await loadPlans();
      return true;
    } catch (e) {
      emit(PlansError(e.toString()));
      return false;
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

  Future<void> calculateAllocationsForAmount(double availableAmount) async {
    try {
      final result = await calculateAllocations(availableAmount);
      emit(AllocationCalculated(
        allocations: result['allocations'] as List<ComponentAllocation>,
        remainingUnallocated: result['remainingUnallocated'] as double,
      ));
    } catch (e) {
      emit(PlansError(e.toString()));
    }
  }

  Future<Map<String, dynamic>> _calculateAllocationsForPlan(
    List<IncomeEntry> incomeEntries,
    List<ExpenseEntry> expenseEntries,
  ) async {
    final totalIncome = incomeEntries.fold(0.0, (sum, e) => sum + e.amount);
    final totalExpense = expenseEntries.fold(0.0, (sum, e) => sum + e.amount);
    final availableAmount = totalIncome - totalExpense;
    return await calculateAllocations(availableAmount);
  }
}

