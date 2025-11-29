import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/hive/hive_module_initializer.dart';
import '../data/models/retirement_plan_model.dart';
import '../core/constants.dart';

/// Hive initializer for the retirement_planner module.
class RetirementPlannerHiveInitializer implements HiveModuleInitializer {
  @override
  Future<void> registerAdapters() async {
    // Register RetirementPlanModel adapter (TypeId: 13)
    final retirementPlanAdapterId = RetirementPlanModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(retirementPlanAdapterId)) {
      Hive.registerAdapter(RetirementPlanModelAdapter());
    }
  }

  @override
  Future<void> openBoxes() async {
    // Open retirement planner boxes
    await Hive.openBox<RetirementPlanModel>(retirementPlanBoxName);
    await Hive.openBox(retirementPreferencesBoxName);
  }
}

