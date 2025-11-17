/*
 * File: ./lib/utilities/investment_planner/domain/entities/expense_entry.dart
 *
 * Purpose:
 *   Domain representation of an Expense Entry within an investment plan.
 *   Links to an ExpenseCategory and specifies the amount.
 *
 * Notes for implementers:
 *   - This file should remain persistence-agnostic.
 *   - The domain layer operates with immutable, type-safe entities.
 */

import 'package:equatable/equatable.dart';

/// Domain model for an Expense Entry.
///
/// Represents a single expense entry in an investment plan,
/// linking to a category and specifying the amount.
class ExpenseEntry extends Equatable {
  /// Unique identifier for the entry (GUID or UUID recommended).
  final String id;

  /// Reference to the expense category ID.
  final String categoryId;

  /// Amount of expense.
  final double amount;

  /// Domain constructor.
  const ExpenseEntry({
    required this.id,
    required this.categoryId,
    required this.amount,
  });

  /// Creates a copy of this ExpenseEntry with the given fields replaced.
  ExpenseEntry copyWith({
    String? id,
    String? categoryId,
    double? amount,
  }) {
    return ExpenseEntry(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
    );
  }

  @override
  List<Object?> get props => [id, categoryId, amount];
}

