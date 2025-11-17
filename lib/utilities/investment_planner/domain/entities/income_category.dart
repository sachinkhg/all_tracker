/*
 * File: ./lib/utilities/investment_planner/domain/entities/income_category.dart
 *
 * Purpose:
 *   Domain representation of an Income Category used as a reusable template
 *   for income sources (e.g., Salary, Dividend).
 *
 * Notes for implementers:
 *   - This file should remain persistence-agnostic.
 *   - The domain layer operates with immutable, type-safe entities.
 */

import 'package:equatable/equatable.dart';

/// Domain model for an Income Category.
///
/// Represents a reusable category template for income sources.
class IncomeCategory extends Equatable {
  /// Unique identifier for the category (GUID or UUID recommended).
  final String id;

  /// Human-readable category name (e.g., "Salary", "Dividend").
  final String name;

  /// Domain constructor.
  const IncomeCategory({
    required this.id,
    required this.name,
  });

  /// Creates a copy of this IncomeCategory with the given fields replaced.
  IncomeCategory copyWith({
    String? id,
    String? name,
  }) {
    return IncomeCategory(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [id, name];
}

