/*
 * File: ./lib/utilities/investment_planner/domain/entities/income_entry.dart
 *
 * Purpose:
 *   Domain representation of an Income Entry within an investment plan.
 *   Links to an IncomeCategory and specifies the amount.
 *
 * Notes for implementers:
 *   - This file should remain persistence-agnostic.
 *   - The domain layer operates with immutable, type-safe entities.
 */

import 'package:equatable/equatable.dart';

/// Domain model for an Income Entry.
///
/// Represents a single income entry in an investment plan,
/// linking to a category and specifying the amount.
class IncomeEntry extends Equatable {
  /// Unique identifier for the entry (GUID or UUID recommended).
  final String id;

  /// Reference to the income category ID.
  final String categoryId;

  /// Amount of income.
  final double amount;

  /// Domain constructor.
  const IncomeEntry({
    required this.id,
    required this.categoryId,
    required this.amount,
  });

  /// Creates a copy of this IncomeEntry with the given fields replaced.
  IncomeEntry copyWith({
    String? id,
    String? categoryId,
    double? amount,
  }) {
    return IncomeEntry(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
    );
  }

  @override
  List<Object?> get props => [id, categoryId, amount];
}

