import 'package:hive/hive.dart';
import '../../domain/entities/expense_entry.dart';

part 'expense_entry_model.g.dart';

/// ExpenseEntryModel – Data Transfer Object (DTO) / Hive Persistence Model
///
/// Purpose:
/// - Represents a persisted ExpenseEntry entity within Hive.
/// - Used as nested model within InvestmentPlanModel.
/// - `typeId: 11` must be unique across all Hive models.

@HiveType(typeId: 11)
class ExpenseEntryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String categoryId;

  @HiveField(2)
  double amount;

  ExpenseEntryModel({
    required this.id,
    required this.categoryId,
    required this.amount,
  });

  factory ExpenseEntryModel.fromEntity(ExpenseEntry entry) => ExpenseEntryModel(
        id: entry.id,
        categoryId: entry.categoryId,
        amount: entry.amount,
      );

  ExpenseEntry toEntity() => ExpenseEntry(
        id: id,
        categoryId: categoryId,
        amount: amount,
      );
}

