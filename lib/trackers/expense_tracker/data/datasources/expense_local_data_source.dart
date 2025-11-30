/*
 * File: expense_local_data_source.dart
 *
 * Purpose:
 *   Hive-backed local data source for Expense objects. This file provides an
 *   abstract contract (ExpenseLocalDataSource) and a Hive implementation
 *   (ExpenseLocalDataSourceImpl) that persist ExpenseModel instances into a Hive box.
 *
 * Serialization rules (high level):
 *   - The concrete Hive adapter and the ExpenseModel DTO live in ../models/expense_model.dart.
 *   - Nullable fields, defaults, and any custom conversion are defined on ExpenseModel.
 *     Refer to ExpenseModel for which fields are nullable and default values.
 *   - Keys used for storage: expense.id (String) is used as the Hive key (not an auto-increment).
 *
 * Compatibility guidance:
 *   - Do NOT reuse Hive field numbers in expense_model.dart when adding/removing fields.
 *   - When changing the model layout or field numbers, update migration_notes.md
 *     with the adapter version and migration steps.
 *   - Any backward-compatibility conversions (legacy values -> new schema) should be
 *     implemented in ExpenseModel (factory / fromEntity / fromJson) so the data source
 *     remains thin and focused on persistence.
 *
 * Developer notes:
 *   - This file intentionally does not perform model conversions — it delegates that
 *     responsibility to ExpenseModel. Keep storage operations (put/get/delete) simple.
 *   - If you add caching, locking, or batch operations, maintain the invariant that
 *     keys are expense.id and that ExpenseModel instances match the Hive adapter version.
 */

import 'package:hive/hive.dart';
import '../models/expense_model.dart';
import '../../domain/entities/expense_group.dart';

/// Abstract data source for local (Hive) expense storage.
///
/// Implementations should be simple adapters that read/write ExpenseModel instances.
/// Conversions between domain entity and DTO should be implemented in ExpenseModel.
abstract class ExpenseLocalDataSource {
  /// Returns all expenses stored in the local box.
  Future<List<ExpenseModel>> getAllExpenses();

  /// Returns a single ExpenseModel by its string id key, or null if not found.
  Future<ExpenseModel?> getExpenseById(String id);

  /// Returns expenses filtered by group.
  Future<List<ExpenseModel>> getExpensesByGroup(ExpenseGroup group);

  /// Returns expenses within a date range.
  Future<List<ExpenseModel>> getExpensesByDateRange(DateTime start, DateTime end);

  /// Returns expenses filtered by group and date range.
  Future<List<ExpenseModel>> getExpensesByGroupAndDateRange(
    ExpenseGroup? group,
    DateTime? start,
    DateTime? end,
  );

  /// Persists a new ExpenseModel. The implementation is expected to use expense.id as key.
  Future<void> createExpense(ExpenseModel expense);

  /// Updates an existing ExpenseModel (or creates it if missing) — uses the same
  /// semantics as Hive's `put` (overwrite if exists).
  Future<void> updateExpense(ExpenseModel expense);

  /// Deletes an expense by its id key.
  Future<void> deleteExpense(String id);
}

/// Hive implementation of [ExpenseLocalDataSource].
///
/// This class treats the provided [box] as the single source of truth for
/// ExpenseModel persistence. It uses `expense.id` (String) as the Hive key — this keeps
/// keys stable across app runs and simplifies lookup.
///
/// Important:
///  - Any legacy value handling (e.g. migrating an old string format to a new enum)
///    should be done inside ExpenseModel (e.g., ExpenseModel.fromEntity/fromJson).
///  - The box must be registered with the appropriate adapter for ExpenseModel before
///    this class is constructed.
class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  /// Hive box that stores [ExpenseModel] entries.
  ///
  /// Rationale: using a typed Box<ExpenseModel> enforces compile-time safety and
  /// ensures the Hive adapter for ExpenseModel is used for serialization.
  final Box<ExpenseModel> box;

  /// Create the local data source with the provided Hive box.
  ///
  /// The box should be opened and the ExpenseModel adapter registered prior to
  /// passing it here (typically during app initialization in core/hive initializer).
  ExpenseLocalDataSourceImpl(this.box);

  @override
  Future<void> createExpense(ExpenseModel expense) async {
    // Use expense.id as the key. This keeps keys consistent and human-readable.
    // We intentionally rely on Hive's `put` semantics — it will create or overwrite.
    await box.put(expense.id, expense);
  }

  @override
  Future<void> deleteExpense(String id) async {
    // Remove the entry with the given id key. No additional logic here to keep
    // the data source thin; domain-level cascade deletes (if any) should be handled
    // by the repository/usecase layer.
    await box.delete(id);
  }

  @override
  Future<ExpenseModel?> getExpenseById(String id) async {
    // Direct box lookup by string key. Returns null if not present.
    // If additional compatibility work is needed (e.g. rehydration), implement it
    // in ExpenseModel (constructor/factory) so this call remains simple.
    return box.get(id);
  }

  @override
  Future<List<ExpenseModel>> getAllExpenses() async {
    // Convert box values iterable to a list. Ordering is the insertion order from Hive.
    // If deterministic sorting is required (e.g., by date), do it at the
    // repository/presentation layer rather than here.
    return box.values.toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByGroup(ExpenseGroup group) async {
    final allExpenses = box.values.toList();
    return allExpenses.where((expense) => expense.group == group.name).toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final allExpenses = box.values.toList();
    // Normalize dates to compare only date part (ignore time)
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    return allExpenses.where((expense) {
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      // Include dates that are >= startDate and <= endDate (inclusive)
      return expenseDate.compareTo(startDate) >= 0 && expenseDate.compareTo(endDate) <= 0;
    }).toList();
  }

  @override
  Future<List<ExpenseModel>> getExpensesByGroupAndDateRange(
    ExpenseGroup? group,
    DateTime? start,
    DateTime? end,
  ) async {
    var expenses = box.values.toList();

    // Apply group filter if provided
    if (group != null) {
      expenses = expenses.where((expense) => expense.group == group.name).toList();
    }

    // Apply date range filter if provided
    if (start != null && end != null) {
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day);
      
      expenses = expenses.where((expense) {
        final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
        // Include dates that are >= startDate and <= endDate (inclusive)
        return expenseDate.compareTo(startDate) >= 0 && expenseDate.compareTo(endDate) <= 0;
      }).toList();
    }

    return expenses;
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    // Update uses the same `put` as create — overwrites existing entry with same key.
    // This keeps create/update semantics unified and reduces duplication.
    await box.put(expense.id, expense);
  }
}

