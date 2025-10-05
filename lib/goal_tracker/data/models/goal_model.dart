import 'package:hive/hive.dart';
import '../../domain/entities/goal.dart';

part 'goal_model.g.dart'; // Build_runner will generate this file

// Hive model for Goal (data layer)
@HiveType(typeId: 0)
class GoalModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? targetDate;

  @HiveField(4)
  String? context;

  @HiveField(5)
  bool isCompleted = false;

  GoalModel({
    required this.id,
    required this.name,
    this.description,
    this.targetDate,
    this.context,
    this.isCompleted = false,
  });

  // Convert from domain entity to model
  factory GoalModel.fromEntity(Goal g) => GoalModel(
        id: g.id,
        name: g.name,
        description: g.description,
        targetDate: g.targetDate, 
        context: g.context,
        isCompleted: g.isCompleted,
      );

  // Convert model back to domain entity
  Goal toEntity() => Goal(
        id: id,
        name: name,
        description: description,
        targetDate: targetDate,
        context: context,
        isCompleted: isCompleted,
      );
}
