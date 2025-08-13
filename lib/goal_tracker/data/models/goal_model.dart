import 'package:hive/hive.dart';
import 'milestone_model.dart';

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
  List<MilestoneModel> milestones;

  GoalModel({
    required this.id,
    required this.title,
    required this.description,
    List<MilestoneModel>? milestones,
  }) : milestones = milestones ?? [];
}
