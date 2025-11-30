/*
 * File: ./lib/trackers/expense_tracker/domain/entities/expense.dart
 *
 * Purpose:
 *   Domain representation of an Expense used throughout the application business logic.
 *   This file defines the plain domain entity (immutable, equatable) and documents
 *   how it maps to persistence DTOs / Hive models (those mapper functions live in
 *   the data layer / local datasource).
 *
 * Serialization rules (for implementers of DTO / Hive adapters):
 *   - `id` (String)         : non-nullable, unique identifier (GUID-like). Expected to be persisted.
 *   - `date` (DateTime)     : non-nullable, date of the expense transaction.
 *   - `description` (String): non-nullable, description of the expense.
 *   - `amount` (double)     : non-nullable, amount (positive for debit/expense, negative for credit/income).
 *   - `group` (ExpenseGroup): non-nullable, category/group for the expense.
 *   - `createdAt` (DateTime): non-nullable, timestamp of creation.
 *   - `updatedAt` (DateTime): non-nullable, timestamp of last update.
 *
 * Compatibility guidance:
 *   - When adding/removing persisted fields, DO NOT reuse Hive field numbers previously used.
 *   - Any change to persisted shape or Hive field numbers must be recorded in migration_notes.md
 *     and corresponding migration code must be added to the local data source.
 *   - Mapper helpers (e.g., ExpenseModel.fromEntity(), ExpenseModel.toEntity()) should explicitly handle
 *     legacy values (for instance missing fields => default to appropriate values).
 *
 * Notes for implementers:
 *   - This file intentionally contains only the pure domain entity and no persistence annotations.
 *     Keep persistence concerns (Hive annotations, adapters) inside the data layer to avoid
 *     coupling the domain layer to a storage implementation.
 */

import 'package:equatable/equatable.dart';
import 'expense_group.dart';

/// Domain model for an Expense.
///
/// This class is intended for use inside the domain and presentation layers only.
/// Persistence-specific mapping (Hive fields, DTO serialization) should live in the
/// data/local layer (e.g., `expense_model.dart`) which converts
/// between this entity and the stored representation.
class Expense extends Equatable {
  /// Unique identifier for the expense (GUID recommended).
  ///
  /// Persistence hint: typically stored as the primary id in the DTO.
  /// Expected Hive field number (data layer): 0.
  final String id;

  /// Date of the expense transaction.
  ///
  /// Persistence hint: non-nullable in domain; stores the date when the expense occurred.
  /// Expected Hive field number (data layer): 1.
  final DateTime date;

  /// Description of the expense.
  ///
  /// Persistence hint: non-nullable in domain; user-provided description.
  /// Expected Hive field number (data layer): 2.
  final String description;

  /// Amount of the expense (positive for debit/expense, negative for credit/income).
  ///
  /// Persistence hint: non-nullable in domain; positive values represent expenses,
  /// negative values represent income/credits.
  /// Expected Hive field number (data layer): 3.
  final double amount;

  /// Category/group for the expense.
  ///
  /// Persistence hint: non-nullable in domain; enum value stored as string or int.
  /// Expected Hive field number (data layer): 4.
  final ExpenseGroup group;

  /// Timestamp of creation.
  ///
  /// Persistence hint: non-nullable in domain; represents when the expense was created.
  /// Expected Hive field number (data layer): 5.
  final DateTime createdAt;

  /// Timestamp of last update.
  ///
  /// Persistence hint: non-nullable in domain; represents when the expense was last modified.
  /// Expected Hive field number (data layer): 6.
  final DateTime updatedAt;

  /// Domain constructor.
  ///
  /// Keep this immutable so instances can be compared and used in const contexts.
  const Expense({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.group,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        description,
        amount,
        group,
        createdAt,
        updatedAt,
      ];

  /// Creates a copy of this Expense with the given fields replaced.
  ///
  /// Useful for updates where only certain fields change.
  Expense copyWith({
    String? id,
    DateTime? date,
    String? description,
    double? amount,
    ExpenseGroup? group,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      group: group ?? this.group,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns true if this expense is a debit (positive amount).
  bool get isDebit => amount > 0;

  /// Returns true if this expense is a credit (negative amount).
  bool get isCredit => amount < 0;
}

