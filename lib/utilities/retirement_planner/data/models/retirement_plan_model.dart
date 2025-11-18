import 'package:hive/hive.dart';
import '../../domain/entities/retirement_plan.dart';

part 'retirement_plan_model.g.dart';

/// RetirementPlanModel – Data Transfer Object (DTO) / Hive Persistence Model
///
/// Purpose:
/// - Represents a persisted RetirementPlan entity within Hive.
/// - Contains all retirement planning inputs, advance inputs, and calculated outputs.
/// - `typeId: 13` must be unique across all Hive models.

@HiveType(typeId: 13)
class RetirementPlanModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime dob;

  @HiveField(3)
  int retirementAge;

  @HiveField(4)
  int lifeExpectancy;

  @HiveField(5)
  double inflationRate;

  @HiveField(6)
  double postRetirementReturnRate;

  @HiveField(7)
  double preRetirementReturnRate;

  @HiveField(8)
  double preRetirementReturnRatioVariation;

  @HiveField(9)
  double monthlyExpensesVariation;

  @HiveField(10)
  double currentMonthlyExpenses;

  @HiveField(11)
  double currentSavings;

  @HiveField(12)
  double? periodForIncome;

  @HiveField(13)
  double? preRetirementReturnRateCalculated;

  @HiveField(14)
  double? monthlyExpensesAtRetirement;

  @HiveField(15)
  double? totalCorpusNeeded;

  @HiveField(16)
  double? futureValueOfCurrentInvestment;

  @HiveField(17)
  double? corpusRequiredToBuild;

  @HiveField(18)
  double? monthlyInvestment;

  @HiveField(19)
  double? yearlyInvestment;

  @HiveField(20)
  DateTime createdAt;

  @HiveField(21)
  DateTime updatedAt;

  RetirementPlanModel({
    required this.id,
    required this.name,
    required this.dob,
    required this.retirementAge,
    required this.lifeExpectancy,
    required this.inflationRate,
    required this.postRetirementReturnRate,
    required this.preRetirementReturnRate,
    required this.preRetirementReturnRatioVariation,
    required this.monthlyExpensesVariation,
    required this.currentMonthlyExpenses,
    required this.currentSavings,
    this.periodForIncome,
    this.preRetirementReturnRateCalculated,
    this.monthlyExpensesAtRetirement,
    this.totalCorpusNeeded,
    this.futureValueOfCurrentInvestment,
    this.corpusRequiredToBuild,
    this.monthlyInvestment,
    this.yearlyInvestment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RetirementPlanModel.fromEntity(RetirementPlan plan) =>
      RetirementPlanModel(
        id: plan.id,
        name: plan.name,
        dob: plan.dob,
        retirementAge: plan.retirementAge,
        lifeExpectancy: plan.lifeExpectancy,
        inflationRate: plan.inflationRate,
        postRetirementReturnRate: plan.postRetirementReturnRate,
        preRetirementReturnRate: plan.preRetirementReturnRate,
        preRetirementReturnRatioVariation: plan.preRetirementReturnRatioVariation,
        monthlyExpensesVariation: plan.monthlyExpensesVariation,
        currentMonthlyExpenses: plan.currentMonthlyExpenses,
        currentSavings: plan.currentSavings,
        periodForIncome: plan.periodForIncome,
        preRetirementReturnRateCalculated: plan.preRetirementReturnRateCalculated,
        monthlyExpensesAtRetirement: plan.monthlyExpensesAtRetirement,
        totalCorpusNeeded: plan.totalCorpusNeeded,
        futureValueOfCurrentInvestment: plan.futureValueOfCurrentInvestment,
        corpusRequiredToBuild: plan.corpusRequiredToBuild,
        monthlyInvestment: plan.monthlyInvestment,
        yearlyInvestment: plan.yearlyInvestment,
        createdAt: plan.createdAt,
        updatedAt: plan.updatedAt,
      );

  RetirementPlan toEntity() => RetirementPlan(
        id: id,
        name: name,
        dob: dob,
        retirementAge: retirementAge,
        lifeExpectancy: lifeExpectancy,
        inflationRate: inflationRate,
        postRetirementReturnRate: postRetirementReturnRate,
        preRetirementReturnRate: preRetirementReturnRate,
        preRetirementReturnRatioVariation: preRetirementReturnRatioVariation,
        monthlyExpensesVariation: monthlyExpensesVariation,
        currentMonthlyExpenses: currentMonthlyExpenses,
        currentSavings: currentSavings,
        periodForIncome: periodForIncome,
        preRetirementReturnRateCalculated: preRetirementReturnRateCalculated,
        monthlyExpensesAtRetirement: monthlyExpensesAtRetirement,
        totalCorpusNeeded: totalCorpusNeeded,
        futureValueOfCurrentInvestment: futureValueOfCurrentInvestment,
        corpusRequiredToBuild: corpusRequiredToBuild,
        monthlyInvestment: monthlyInvestment,
        yearlyInvestment: yearlyInvestment,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

