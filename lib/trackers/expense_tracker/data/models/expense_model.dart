import 'package:hive/hive.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_group.dart';

part 'expense_model.g.dart'; // Generated via build_runner

/// ---------------------------------------------------------------------------
/// ExpenseModel – Data Transfer Object (DTO) / Hive Persistence Model
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Represents a persisted `Expense` entity within Hive.
/// - Acts as a bridge between domain-layer entities and Hive storage.
///
/// Schema & Migration Guidelines:
/// - Each `@HiveField` index is permanent once written to storage.
/// - Never reuse or reorder field numbers — doing so will corrupt persisted data.
/// - Add new fields only at the end with new, unique field numbers.
/// - Document any changes in `migration_notes.md`.
///
/// TypeId: 24 (as documented in migration_notes.md)
/// ---------------------------------------------------------------------------

@HiveType(typeId: 24)
class ExpenseModel extends HiveObject {
  /// Unique identifier for the expense.
  ///
  /// Hive field number **0** — stable ID, never change or reuse.
  @HiveField(0)
  String id;

  /// Date of the expense transaction.
  ///
  /// Hive field number **1** — required.
  @HiveField(1)
  DateTime date;

  /// Description of the expense.
  ///
  /// Hive field number **2** — required.
  @HiveField(2)
  String description;

  /// Amount of the expense (positive for debit, negative for credit).
  ///
  /// Hive field number **3** — required.
  @HiveField(3)
  double amount;

  /// Category/group for the expense (stored as string).
  ///
  /// Hive field number **4** — required; stored as enum name string.
  @HiveField(4)
  String group;

  /// Timestamp of creation.
  ///
  /// Hive field number **5** — required.
  @HiveField(5)
  DateTime createdAt;

  /// Timestamp of last update.
  ///
  /// Hive field number **6** — required.
  @HiveField(6)
  DateTime updatedAt;

  ExpenseModel({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.group,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to build an [ExpenseModel] from a domain [Expense].
  factory ExpenseModel.fromEntity(Expense expense) => ExpenseModel(
        id: expense.id,
        date: expense.date,
        description: expense.description,
        amount: expense.amount,
        group: expense.group.name,
        createdAt: expense.createdAt,
        updatedAt: expense.updatedAt,
      );

  /// Converts this model back into a domain [Expense] entity.
  Expense toEntity() {
    // Parse the group string back to enum
    ExpenseGroup expenseGroup;
    try {
      expenseGroup = ExpenseGroup.values.firstWhere(
        (e) => e.name == group,
        orElse: () => ExpenseGroup.food, // Default fallback
      );
    } catch (e) {
      // If parsing fails, default to food
      expenseGroup = ExpenseGroup.food;
    }

    return Expense(
      id: id,
      date: date,
      description: description,
      amount: amount,
      group: expenseGroup,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates a copy of this ExpenseModel with the given fields replaced.
  ///
  /// Useful for updates where only certain fields change.
  ExpenseModel copyWith({
    String? id,
    DateTime? date,
    String? description,
    double? amount,
    String? group,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      group: group ?? this.group,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

