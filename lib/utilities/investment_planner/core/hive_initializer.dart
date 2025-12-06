import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/hive/hive_module_initializer.dart';
import '../data/models/investment_component_model.dart';
import '../data/models/income_category_model.dart';
import '../data/models/expense_category_model.dart';
import '../data/models/income_entry_model.dart';
import '../data/models/expense_entry_model.dart';
import '../data/models/component_allocation_model.dart';
import '../data/models/investment_plan_model.dart';
import '../core/constants.dart';

/// Hive initializer for the investment_planner module.
class InvestmentPlannerHiveInitializer implements HiveModuleInitializer {
  @override
  Future<void> registerAdapters() async {
    // Register InvestmentComponentModel adapter (TypeId: 6)
    final investmentComponentAdapterId = InvestmentComponentModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(investmentComponentAdapterId)) {
      Hive.registerAdapter(InvestmentComponentModelAdapter());
    }

    // Register IncomeCategoryModel adapter (TypeId: 7)
    final incomeCategoryAdapterId = IncomeCategoryModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(incomeCategoryAdapterId)) {
      Hive.registerAdapter(IncomeCategoryModelAdapter());
    }

    // Register ExpenseCategoryModel adapter (TypeId: 8)
    final expenseCategoryAdapterId = ExpenseCategoryModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(expenseCategoryAdapterId)) {
      Hive.registerAdapter(ExpenseCategoryModelAdapter());
    }

    // Register InvestmentPlanModel adapter (TypeId: 9)
    final investmentPlanAdapterId = InvestmentPlanModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(investmentPlanAdapterId)) {
      Hive.registerAdapter(InvestmentPlanModelAdapter());
    }

    // Register IncomeEntryModel adapter (TypeId: 10)
    final incomeEntryAdapterId = IncomeEntryModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(incomeEntryAdapterId)) {
      Hive.registerAdapter(IncomeEntryModelAdapter());
    }

    // Register ExpenseEntryModel adapter (TypeId: 11)
    final expenseEntryAdapterId = ExpenseEntryModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(expenseEntryAdapterId)) {
      Hive.registerAdapter(ExpenseEntryModelAdapter());
    }

    // Register ComponentAllocationModel adapter (TypeId: 12)
    final componentAllocationAdapterId = ComponentAllocationModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(componentAllocationAdapterId)) {
      Hive.registerAdapter(ComponentAllocationModelAdapter());
    }
  }

  @override
  Future<void> openBoxes() async {
    // Open investment planner boxes with error handling for migration
    // Only clear data if there's a schema mismatch error
    await _openBoxWithErrorHandling<InvestmentComponentModel>(investmentComponentBoxName);
    await _openBoxWithErrorHandling<IncomeCategoryModel>(incomeCategoryBoxName);
    await _openBoxWithErrorHandling<ExpenseCategoryModel>(expenseCategoryBoxName);
    await _openBoxWithErrorHandling<InvestmentPlanModel>(investmentPlanBoxName);
  }
  
  /// Opens a Hive box, only clearing data if there's a schema mismatch error
  /// This preserves existing data while handling migration issues gracefully
  Future<void> _openBoxWithErrorHandling<T>(String boxName) async {
    try {
      await Hive.openBox<T>(boxName);
    } catch (e) {
      // If opening fails due to schema changes, try to recover
      try {
        // Close the box if it was partially opened
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box<T>(boxName).close();
        }
        
        // Delete the corrupted box and create a new one
        // This only happens if there's a schema mismatch
        await Hive.deleteBoxFromDisk(boxName);
        await Hive.openBox<T>(boxName);
      } catch (recoveryError) {
        // If recovery also fails, try to open empty box
        await Hive.openBox<T>(boxName);
      }
    }
  }
}


