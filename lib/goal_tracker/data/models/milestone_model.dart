import 'package:hive/hive.dart';
part 'milestone_model.g.dart';  

@HiveType(typeId: 2)
class MilestoneModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? associatedGoalID;

  @HiveField(3)
  DateTime? targetDate; // Defaults to now if not provided

  MilestoneModel({
    required this.id,
    required this.title,
    this.associatedGoalID,
    this.targetDate,
  });
}
