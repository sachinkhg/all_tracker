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

  ComponentAllocationModel({
    required this.componentId,
    required this.allocatedAmount,
  });

  factory ComponentAllocationModel.fromEntity(ComponentAllocation allocation) =>
      ComponentAllocationModel(
        componentId: allocation.componentId,
        allocatedAmount: allocation.allocatedAmount,
      );

  ComponentAllocation toEntity() => ComponentAllocation(
        componentId: componentId,
        allocatedAmount: allocatedAmount,
      );
}

