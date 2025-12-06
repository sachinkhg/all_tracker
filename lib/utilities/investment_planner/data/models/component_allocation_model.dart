import 'package:hive/hive.dart';
import '../../domain/entities/component_allocation.dart';

part 'component_allocation_model.g.dart';

/// ComponentAllocationModel – Data Transfer Object (DTO) / Hive Persistence Model
///
/// Purpose:
/// - Represents a persisted ComponentAllocation entity within Hive.
/// - Used as nested model within InvestmentPlanModel.
/// - `typeId: 12` must be unique across all Hive models.

@HiveType(typeId: 12)
class ComponentAllocationModel extends HiveObject {
  @HiveField(0)
  String componentId;

  @HiveField(1)
  double allocatedAmount;

  @HiveField(2)
  double? actualAmount;

  @HiveField(3)
  bool isCompleted;

  ComponentAllocationModel({
    required this.componentId,
    required this.allocatedAmount,
    this.actualAmount,
    this.isCompleted = false,
  });

  factory ComponentAllocationModel.fromEntity(ComponentAllocation allocation) =>
      ComponentAllocationModel(
        componentId: allocation.componentId,
        allocatedAmount: allocation.allocatedAmount,
        actualAmount: allocation.actualAmount,
        isCompleted: allocation.isCompleted,
      );

  ComponentAllocation toEntity() => ComponentAllocation(
        componentId: componentId,
        allocatedAmount: allocatedAmount,
        actualAmount: actualAmount,
        isCompleted: isCompleted,
      );
}

