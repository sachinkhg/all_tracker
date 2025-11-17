import 'package:hive/hive.dart';
import '../../domain/entities/expense_category.dart';

part 'expense_category_model.g.dart';

/// ExpenseCategoryModel – Data Transfer Object (DTO) / Hive Persistence Model
///
/// Purpose:
/// - Represents a persisted ExpenseCategory entity within Hive.
/// - `typeId: 8` must be unique across all Hive models.

@HiveType(typeId: 8)
class ExpenseCategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  ExpenseCategoryModel({
    required this.id,
    required this.name,
  });

  factory ExpenseCategoryModel.fromEntity(ExpenseCategory category) =>
      ExpenseCategoryModel(
        id: category.id,
        name: category.name,
      );

  ExpenseCategory toEntity() => ExpenseCategory(
        id: id,
        name: name,
      );
}

