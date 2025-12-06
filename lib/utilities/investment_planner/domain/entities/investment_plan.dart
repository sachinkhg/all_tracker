/*
 * File: ./lib/utilities/investment_planner/domain/entities/investment_plan.dart
 *
 * Purpose:
 *   Domain representation of an Investment Plan.
 *   Contains all information for a complete investment plan including
 *   income/expense entries and calculated allocations.
 *
 * Serialization rules (for implementers of DTO / Hive adapters):
 *   - `id` (String)              : non-nullable, globally unique identifier.
 *   - `name` (String)            : non-nullable, plan name.
 *   - `duration` (String)        : non-nullable, "Monthly" or "Yearly".
 *   - `period` (String)          : non-nullable, period identifier (e.g., "Nov 2025").
 *   - `incomeEntries` (List)    : non-nullable, list of income entries.
 *   - `expenseEntries` (List)   : non-nullable, list of expense entries.
 *   - `allocations` (List)       : non-nullable, list of component allocations.
 *   - `createdAt` (DateTime)    : non-nullable, creation timestamp.
 *   - `updatedAt` (DateTime)    : non-nullable, last update timestamp.
 *
 * Notes for implementers:
 *   - This file should remain persistence-agnostic.
 *   - The domain layer operates with immutable, type-safe entities.
 */

import 'package:equatable/equatable.dart';
import 'income_entry.dart';
import 'expense_entry.dart';
import 'component_allocation.dart';
import 'plan_status.dart';

/// Domain model for an Investment Plan.
///
/// Represents a complete investment plan with income/expense entries
/// and calculated component allocations.
class InvestmentPlan extends Equatable {
  /// Unique identifier for the plan (GUID or UUID recommended).
  final String id;

  /// Plan name (e.g., "Investment for Nov 2025").
  final String name;

  /// Duration of the plan (e.g., "Monthly" or "Yearly").
  final String duration;

  /// Period identifier (e.g., "Nov 2025").
  final String period;

  /// Status of the plan (Draft, Approved, Executed).
  final PlanStatus status;

  /// List of income entries in this plan.
  final List<IncomeEntry> incomeEntries;

  /// List of expense entries in this plan.
  final List<ExpenseEntry> expenseEntries;

  /// List of calculated component allocations.
  final List<ComponentAllocation> allocations;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Domain constructor.
  const InvestmentPlan({
    required this.id,
    required this.name,
    required this.duration,
    required this.period,
    this.status = PlanStatus.draft,
    required this.incomeEntries,
    required this.expenseEntries,
    required this.allocations,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this InvestmentPlan with the given fields replaced.
  InvestmentPlan copyWith({
    String? id,
    String? name,
    String? duration,
    String? period,
    PlanStatus? status,
    List<IncomeEntry>? incomeEntries,
    List<ExpenseEntry>? expenseEntries,
    List<ComponentAllocation>? allocations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvestmentPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      period: period ?? this.period,
      status: status ?? this.status,
      incomeEntries: incomeEntries ?? this.incomeEntries,
      expenseEntries: expenseEntries ?? this.expenseEntries,
      allocations: allocations ?? this.allocations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculates the total income amount.
  double get totalIncome {
    return incomeEntries.fold(0.0, (sum, entry) => sum + entry.amount);
  }

  /// Calculates the total expense amount.
  double get totalExpense {
    return expenseEntries.fold(0.0, (sum, entry) => sum + entry.amount);
  }

  /// Calculates the available amount for investment.
  double get availableAmount {
    return totalIncome - totalExpense;
  }

  /// Calculates the total allocated amount.
  double get totalAllocated {
    return allocations.fold(0.0, (sum, allocation) => sum + allocation.allocatedAmount);
  }

  /// Calculates the remaining unallocated amount.
  double get remainingUnallocated {
    return availableAmount - totalAllocated;
  }

  /// Returns true if the plan is editable (only Draft plans are editable).
  bool get isEditable => status == PlanStatus.draft;

  @override
  List<Object?> get props => [
        id,
        name,
        duration,
        period,
        status,
        incomeEntries,
        expenseEntries,
        allocations,
        createdAt,
        updatedAt,
      ];
}

