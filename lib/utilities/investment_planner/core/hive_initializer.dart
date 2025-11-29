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
    // Open investment planner boxes
    await Hive.openBox<InvestmentComponentModel>(investmentComponentBoxName);
    await Hive.openBox<IncomeCategoryModel>(incomeCategoryBoxName);
    await Hive.openBox<ExpenseCategoryModel>(expenseCategoryBoxName);
    await Hive.openBox<InvestmentPlanModel>(investmentPlanBoxName);
  }
}

