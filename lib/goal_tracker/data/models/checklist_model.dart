import 'package:hive/hive.dart';

part 'checklist_model.g.dart';

@HiveType(typeId: 0) // Make sure typeIds are unique in the whole app
class ChecklistModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  ChecklistModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}
