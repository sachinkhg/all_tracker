// lib/utilities/investment_planner/core/injection.dart
// Composition root: wires data -> repository -> usecases -> cubit.

import 'package:hive_flutter/hive_flutter.dart';

import '../data/datasources/investment_component_local_data_source.dart';
import '../data/repositories/investment_component_repository_impl.dart';
import '../data/models/investment_component_model.dart';
import '../domain/usecases/component/create_component.dart';
import '../domain/usecases/component/get_all_components.dart';
import '../domain/usecases/component/get_component_by_id.dart';
import '../domain/usecases/component/update_component.dart';
import '../domain/usecases/component/delete_component.dart';

import '../data/datasources/income_category_local_data_source.dart';
import '../data/repositories/income_category_repository_impl.dart';
import '../data/models/income_category_model.dart';
import '../domain/usecases/income_category/create_income_category.dart';
import '../domain/usecases/income_category/get_all_income_categories.dart';
import '../domain/usecases/income_category/update_income_category.dart';
import '../domain/usecases/income_category/delete_income_category.dart';

import '../data/datasources/expense_category_local_data_source.dart';
import '../data/repositories/expense_category_repository_impl.dart';
import '../data/models/expense_category_model.dart';
import '../domain/usecases/expense_category/create_expense_category.dart';
import '../domain/usecases/expense_category/get_all_expense_categories.dart';
import '../domain/usecases/expense_category/update_expense_category.dart';
import '../domain/usecases/expense_category/delete_expense_category.dart';

import '../data/datasources/investment_plan_local_data_source.dart';
import '../data/repositories/investment_plan_repository_impl.dart';
import '../data/models/investment_plan_model.dart';
import '../domain/usecases/plan/create_plan.dart';
import '../domain/usecases/plan/get_all_plans.dart';
import '../domain/usecases/plan/get_plan_by_id.dart';
import '../domain/usecases/plan/update_plan.dart';
import '../domain/usecases/plan/delete_plan.dart';
import '../domain/usecases/plan/calculate_allocations.dart';

import '../presentation/bloc/investment_component_cubit.dart';
import '../presentation/bloc/income_category_cubit.dart';
import '../presentation/bloc/expense_category_cubit.dart';
import '../presentation/bloc/investment_plan_cubit.dart';

import 'constants.dart';

/// Factory that constructs a fully-wired InvestmentComponentCubit.
InvestmentComponentCubit createInvestmentComponentCubit() {
  final Box<InvestmentComponentModel> box =
      Hive.box<InvestmentComponentModel>(investmentComponentBoxName);

  // Data layer
  final local = InvestmentComponentLocalDataSourceImpl(box);

  // Repository layer
  final repo = InvestmentComponentRepositoryImpl(local);

  // Use-cases
  final getAll = GetAllComponents(repo);
  final getById = GetComponentById(repo);
  final create = CreateComponent(repo);
  final update = UpdateComponent(repo);
  final delete = DeleteComponent(repo);

  // Presentation
  return InvestmentComponentCubit(
    getAll: getAll,
    getById: getById,
    create: create,
    update: update,
    delete: delete,
  );
}

/// Factory that constructs a fully-wired IncomeCategoryCubit.
IncomeCategoryCubit createIncomeCategoryCubit() {
  final Box<IncomeCategoryModel> box =
      Hive.box<IncomeCategoryModel>(incomeCategoryBoxName);

  // Data layer
  final local = IncomeCategoryLocalDataSourceImpl(box);

  // Repository layer
  final repo = IncomeCategoryRepositoryImpl(local);

  // Use-cases
  final getAll = GetAllIncomeCategories(repo);
  final create = CreateIncomeCategory(repo);
  final update = UpdateIncomeCategory(repo);
  final delete = DeleteIncomeCategory(repo);

  // Presentation
  return IncomeCategoryCubit(
    getAll: getAll,
    create: create,
    update: update,
    delete: delete,
  );
}

/// Factory that constructs a fully-wired ExpenseCategoryCubit.
ExpenseCategoryCubit createExpenseCategoryCubit() {
  final Box<ExpenseCategoryModel> box =
      Hive.box<ExpenseCategoryModel>(expenseCategoryBoxName);

  // Data layer
  final local = ExpenseCategoryLocalDataSourceImpl(box);

  // Repository layer
  final repo = ExpenseCategoryRepositoryImpl(local);

  // Use-cases
  final getAll = GetAllExpenseCategories(repo);
  final create = CreateExpenseCategory(repo);
  final update = UpdateExpenseCategory(repo);
  final delete = DeleteExpenseCategory(repo);

  // Presentation
  return ExpenseCategoryCubit(
    getAll: getAll,
    create: create,
    update: update,
    delete: delete,
  );
}

/// Factory that constructs a fully-wired InvestmentPlanCubit.
InvestmentPlanCubit createInvestmentPlanCubit() {
  final Box<InvestmentPlanModel> planBox =
      Hive.box<InvestmentPlanModel>(investmentPlanBoxName);
  final Box<InvestmentComponentModel> componentBox =
      Hive.box<InvestmentComponentModel>(investmentComponentBoxName);

  // Data layer
  final planLocal = InvestmentPlanLocalDataSourceImpl(planBox);
  final componentLocal = InvestmentComponentLocalDataSourceImpl(componentBox);

  // Repository layer
  final planRepo = InvestmentPlanRepositoryImpl(planLocal);
  final componentRepo = InvestmentComponentRepositoryImpl(componentLocal);

  // Use-cases
  final getAllPlans = GetAllPlans(planRepo);
  final getPlanById = GetPlanById(planRepo);
  final createPlan = CreatePlan(planRepo);
  final updatePlan = UpdatePlan(planRepo);
  final deletePlan = DeletePlan(planRepo);
  final calculateAllocations = CalculateAllocations(componentRepo);

  // Presentation
  return InvestmentPlanCubit(
    getAllPlans: getAllPlans,
    getPlanById: getPlanById,
    createPlan: createPlan,
    updatePlan: updatePlan,
    deletePlan: deletePlan,
    calculateAllocations: calculateAllocations,
  );
}

