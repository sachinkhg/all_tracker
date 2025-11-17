/*
 * File: ./lib/utilities/investment_planner/domain/entities/expense_category.dart
 *
 * Purpose:
 *   Domain representation of an Expense Category used as a reusable template
 *   for expense sources (e.g., Bill, EMI).
 *
 * Notes for implementers:
 *   - This file should remain persistence-agnostic.
 *   - The domain layer operates with immutable, type-safe entities.
 */

import 'package:equatable/equatable.dart';

/// Domain model for an Expense Category.
///
/// Represents a reusable category template for expense sources.
class ExpenseCategory extends Equatable {
  /// Unique identifier for the category (GUID or UUID recommended).
  final String id;

  /// Human-readable category name (e.g., "Bill", "EMI").
  final String name;

  /// Domain constructor.
  const ExpenseCategory({
    required this.id,
    required this.name,
  });

  /// Creates a copy of this ExpenseCategory with the given fields replaced.
  ExpenseCategory copyWith({
    String? id,
    String? name,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [id, name];
}

