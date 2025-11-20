import 'package:hive/hive.dart';
import '../../domain/entities/expense.dart';
import '../../core/constants.dart';

part 'expense_model.g.dart';

/// Hive model for Expense entity (typeId: 20).
@HiveType(typeId: 20)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int categoryIndex; // Store enum as int

  @HiveField(4)
  double amount;

  @HiveField(5)
  String currency;

  @HiveField(6)
  String? description;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  ExpenseModel({
    required this.id,
    required this.tripId,
    required this.date,
    required this.categoryIndex,
    required this.amount,
    required this.currency,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseModel.fromEntity(Expense expense) => ExpenseModel(
        id: expense.id,
        tripId: expense.tripId,
        date: expense.date,
        categoryIndex: expense.category.index,
        amount: expense.amount,
        currency: expense.currency,
        description: expense.description,
        createdAt: expense.createdAt,
        updatedAt: expense.updatedAt,
      );

  Expense toEntity() => Expense(
        id: id,
        tripId: tripId,
        date: date,
        category: ExpenseCategory.values[categoryIndex],
        amount: amount,
        currency: currency,
        description: description,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

