import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/investment_plan.dart';
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
    required String duration,
    required String period,
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

      final plan = InvestmentPlan(
        id: planId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        duration: duration,
        period: period,
        incomeEntries: incomeEntries,
        expenseEntries: expenseEntries,
        allocations: allocationsResult['allocations'] as List<ComponentAllocation>,
        createdAt: planId != null ? now : now, // Keep original if updating
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

