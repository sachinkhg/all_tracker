import 'package:hive/hive.dart';
import '../../domain/entities/income_entry.dart';

part 'income_entry_model.g.dart';

/// IncomeEntryModel – Data Transfer Object (DTO) / Hive Persistence Model
///
/// Purpose:
/// - Represents a persisted IncomeEntry entity within Hive.
/// - Used as nested model within InvestmentPlanModel.
/// - `typeId: 10` must be unique across all Hive models.

@HiveType(typeId: 10)
class IncomeEntryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String categoryId;

  @HiveField(2)
  double amount;

  IncomeEntryModel({
    required this.id,
    required this.categoryId,
    required this.amount,
  });

  factory IncomeEntryModel.fromEntity(IncomeEntry entry) => IncomeEntryModel(
        id: entry.id,
        categoryId: entry.categoryId,
        amount: entry.amount,
      );

  IncomeEntry toEntity() => IncomeEntry(
        id: id,
        categoryId: categoryId,
        amount: amount,
      );
}

