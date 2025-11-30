import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/hive/hive_module_initializer.dart';
import '../data/models/expense_model.dart';
import 'constants.dart';

/// Hive initializer for the expense_tracker module.
///
/// This class handles registration of all Hive adapters and opening of all
/// Hive boxes required by the expense_tracker module. It implements the
/// HiveModuleInitializer interface so it can be discovered and called by
/// the central HiveInitializer.
class ExpenseTrackerHiveInitializer implements HiveModuleInitializer {
  @override
  Future<void> registerAdapters() async {
    // Register ExpenseModel adapter (TypeId: 24)
    final expenseAdapterId = ExpenseModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(expenseAdapterId)) {
      Hive.registerAdapter(ExpenseModelAdapter());
    }
  }

  @override
  Future<void> openBoxes() async {
    // Open expense tracker box
    await Hive.openBox<ExpenseModel>(expenseTrackerBoxName);
  }
}

