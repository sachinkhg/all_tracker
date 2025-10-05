import 'package:all_tracker/goal_tracker/data/models/goal_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveInitializer {

  static Future<Box<GoalModel>> initialize() async {
    await Hive.initFlutter();
    final adapterId = GoalModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(adapterId)) {
      Hive.registerAdapter(GoalModelAdapter());
    }
  var box = await Hive.openBox<GoalModel>('goals_box');
  return box;
  }
}