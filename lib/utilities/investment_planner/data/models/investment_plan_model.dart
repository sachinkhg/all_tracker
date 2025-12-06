import 'package:hive/hive.dart';
import '../../domain/entities/investment_plan.dart';
import '../../domain/entities/plan_status.dart';
import 'income_entry_model.dart';
import 'expense_entry_model.dart';
import 'component_allocation_model.dart';

part 'investment_plan_model.g.dart';

/// InvestmentPlanModel – Data Transfer Object (DTO) / Hive Persistence Model
///
/// Purpose:
/// - Represents a persisted InvestmentPlan entity within Hive.
/// - Contains nested lists of income entries, expense entries, and allocations.
/// - `typeId: 9` must be unique across all Hive models.

@HiveType(typeId: 9)
class InvestmentPlanModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String duration;

  @HiveField(3)
  String period;

  @HiveField(9)
  String status;

  @HiveField(4)
  List<IncomeEntryModel> incomeEntries;

  @HiveField(5)
  List<ExpenseEntryModel> expenseEntries;

  @HiveField(6)
  List<ComponentAllocationModel> allocations;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  InvestmentPlanModel({
    required this.id,
    required this.name,
    required this.duration,
    required this.period,
    String? status,
    required this.incomeEntries,
    required this.expenseEntries,
    required this.allocations,
    required this.createdAt,
    required this.updatedAt,
  }) : status = status ?? PlanStatus.draft.toJson();

  factory InvestmentPlanModel.fromEntity(InvestmentPlan plan) =>
      InvestmentPlanModel(
        id: plan.id,
        name: plan.name,
        duration: plan.duration,
        period: plan.period,
        status: plan.status.toJson(),
        incomeEntries: plan.incomeEntries
            .map((e) => IncomeEntryModel.fromEntity(e))
            .toList(),
        expenseEntries: plan.expenseEntries
            .map((e) => ExpenseEntryModel.fromEntity(e))
            .toList(),
        allocations: plan.allocations
            .map((a) => ComponentAllocationModel.fromEntity(a))
            .toList(),
        createdAt: plan.createdAt,
        updatedAt: plan.updatedAt,
      );

  InvestmentPlan toEntity() => InvestmentPlan(
        id: id,
        name: name,
        duration: duration.isNotEmpty ? duration : 'Monthly',
        period: period.isNotEmpty ? period : _formatPeriod(createdAt),
        status: PlanStatus.fromJson(status),
        incomeEntries: incomeEntries.map((e) => e.toEntity()).toList(),
        expenseEntries: expenseEntries.map((e) => e.toEntity()).toList(),
        allocations: allocations.map((a) => a.toEntity()).toList(),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
  
  // Helper method to format period from date
  String _formatPeriod(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }
}

