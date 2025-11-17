import 'package:hive/hive.dart';
import '../../domain/entities/investment_component.dart';

part 'investment_component_model.g.dart';

/// InvestmentComponentModel – Data Transfer Object (DTO) / Hive Persistence Model
///
/// Purpose:
/// - Represents a persisted InvestmentComponent entity within Hive.
/// - Acts as a bridge between domain-layer entities and Hive storage.
///
/// Schema & Migration Guidelines:
/// - Each @HiveField index is permanent once written to storage.
/// - Never reuse or reorder field numbers.
/// - `typeId: 6` must be unique across all Hive models.

@HiveType(typeId: 6)
class InvestmentComponentModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double percentage;

  @HiveField(3)
  double? minLimit;

  @HiveField(4)
  double? maxLimit;

  @HiveField(5)
  int priority;

  InvestmentComponentModel({
    required this.id,
    required this.name,
    required this.percentage,
    this.minLimit,
    this.maxLimit,
    required this.priority,
  });

  factory InvestmentComponentModel.fromEntity(InvestmentComponent component) =>
      InvestmentComponentModel(
        id: component.id,
        name: component.name,
        percentage: component.percentage,
        minLimit: component.minLimit,
        maxLimit: component.maxLimit,
        priority: component.priority,
      );

  InvestmentComponent toEntity() => InvestmentComponent(
        id: id,
        name: name,
        percentage: percentage,
        minLimit: minLimit,
        maxLimit: maxLimit,
        priority: priority,
      );
}

