import 'package:hive/hive.dart';

part 'goal_model.g.dart';

@HiveType(typeId: 3)
class GoalModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  // Optional milestones
  @HiveField(3)
  List<String> milestoneIds;

  @HiveField(4)
  DateTime? targetDate;

  GoalModel({
    required this.id,
    required this.title,
    required this.description,
    List<String>? milestoneIds,
    this.targetDate,
  })  : milestoneIds = milestoneIds ?? [];
}
