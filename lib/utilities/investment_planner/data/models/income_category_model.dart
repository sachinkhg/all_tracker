import 'package:hive/hive.dart';
import '../../domain/entities/income_category.dart';

part 'income_category_model.g.dart';

/// IncomeCategoryModel – Data Transfer Object (DTO) / Hive Persistence Model
///
/// Purpose:
/// - Represents a persisted IncomeCategory entity within Hive.
/// - `typeId: 7` must be unique across all Hive models.

@HiveType(typeId: 7)
class IncomeCategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  IncomeCategoryModel({
    required this.id,
    required this.name,
  });

  factory IncomeCategoryModel.fromEntity(IncomeCategory category) =>
      IncomeCategoryModel(
        id: category.id,
        name: category.name,
      );

  IncomeCategory toEntity() => IncomeCategory(
        id: id,
        name: name,
      );
}

