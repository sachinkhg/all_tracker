/*
 * File: ./lib/utilities/retirement_planner/domain/entities/retirement_plan.dart
 *
 * Purpose:
 *   Domain representation of a Retirement Plan.
 *   Contains all information for retirement planning including
 *   user inputs, advance inputs, and calculated outputs.
 *
 * Properties mapping (A-S):
 *   A: name (Input)
 *   B: dob - Date of Birth (Input)
 *   C: retirementAge (Input)
 *   D: lifeExpectancy (Input)
 *   E: inflationRate (Advance Input, Otherwise default)
 *   F: postRetirementReturnRate (Advance Input, Otherwise default)
 *   G: preRetirementReturnRate (Input)
 *   H: preRetirementReturnRatioVariation (Advance Input, Otherwise default)
 *   I: monthlyExpensesVariation (Advance Input, Otherwise default)
 *   J: periodForIncome (Intermediate Calculation)
 *   K: currentMonthlyExpenses (Input)
 *   L: currentSavings (Input)
 *   M: preRetirementReturnRateCalculated (Intermediate Calculation)
 *   N: monthlyExpensesAtRetirement (Output)
 *   O: totalCorpusNeeded (Output)
 *   P: futureValueOfCurrentInvestment (Intermediate Calculation)
 *   Q: corpusRequiredToBuild (Final Output)
 *   R: monthlyInvestment (Final Output)
 *   S: yearlyInvestment (Final Output)
 */

import 'package:equatable/equatable.dart';

/// Domain model for a Retirement Plan.
///
/// Represents a complete retirement plan with user inputs and calculated outputs.
class RetirementPlan extends Equatable {
  /// Unique identifier for the plan (GUID or UUID recommended).
  final String id;

  /// A: Name (Input)
  final String name;

  /// B: Date of Birth (Input)
  final DateTime dob;

  /// C: Retirement Age (Input)
  final int retirementAge;

  /// D: Life Expectancy (Input)
  final int lifeExpectancy;

  /// E: Inflation Rate (Advance Input, Otherwise default)
  final double inflationRate;

  /// F: Post-Retirement Return Rate (Advance Input, Otherwise default)
  final double postRetirementReturnRate;

  /// G: Pre-Retirement Return Rate (Input)
  final double preRetirementReturnRate;

  /// H: Pre-Retirement Return Ratio Variation (Advance Input, Otherwise default)
  final double preRetirementReturnRatioVariation;

  /// I: Monthly Expenses Variation (Advance Input, Otherwise default)
  final double monthlyExpensesVariation;

  /// K: Current Monthly Expenses (Input)
  final double currentMonthlyExpenses;

  /// L: Current Savings (Input)
  final double currentSavings;

  /// J: Period for which income is needed (Intermediate Calculation)
  final double? periodForIncome;

  /// M: Pre-Retirement Return Rate Calculated (Intermediate Calculation)
  final double? preRetirementReturnRateCalculated;

  /// N: Monthly Expenses at Retirement (Output)
  final double? monthlyExpensesAtRetirement;

  /// O: Total Corpus Needed for Retirement (Output)
  final double? totalCorpusNeeded;

  /// P: Future Value of Current Investment (Intermediate Calculation)
  final double? futureValueOfCurrentInvestment;

  /// Q: Corpus Required to build (Final Output)
  final double? corpusRequiredToBuild;

  /// R: Monthly Investment (Final Output)
  final double? monthlyInvestment;

  /// S: Yearly Investment (Final Output)
  final double? yearlyInvestment;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Domain constructor.
  const RetirementPlan({
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

  /// Creates a copy of this RetirementPlan with the given fields replaced.
  RetirementPlan copyWith({
    String? id,
    String? name,
    DateTime? dob,
    int? retirementAge,
    int? lifeExpectancy,
    double? inflationRate,
    double? postRetirementReturnRate,
    double? preRetirementReturnRate,
    double? preRetirementReturnRatioVariation,
    double? monthlyExpensesVariation,
    double? currentMonthlyExpenses,
    double? currentSavings,
    double? periodForIncome,
    double? preRetirementReturnRateCalculated,
    double? monthlyExpensesAtRetirement,
    double? totalCorpusNeeded,
    double? futureValueOfCurrentInvestment,
    double? corpusRequiredToBuild,
    double? monthlyInvestment,
    double? yearlyInvestment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RetirementPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      retirementAge: retirementAge ?? this.retirementAge,
      lifeExpectancy: lifeExpectancy ?? this.lifeExpectancy,
      inflationRate: inflationRate ?? this.inflationRate,
      postRetirementReturnRate: postRetirementReturnRate ?? this.postRetirementReturnRate,
      preRetirementReturnRate: preRetirementReturnRate ?? this.preRetirementReturnRate,
      preRetirementReturnRatioVariation: preRetirementReturnRatioVariation ?? this.preRetirementReturnRatioVariation,
      monthlyExpensesVariation: monthlyExpensesVariation ?? this.monthlyExpensesVariation,
      currentMonthlyExpenses: currentMonthlyExpenses ?? this.currentMonthlyExpenses,
      currentSavings: currentSavings ?? this.currentSavings,
      periodForIncome: periodForIncome ?? this.periodForIncome,
      preRetirementReturnRateCalculated: preRetirementReturnRateCalculated ?? this.preRetirementReturnRateCalculated,
      monthlyExpensesAtRetirement: monthlyExpensesAtRetirement ?? this.monthlyExpensesAtRetirement,
      totalCorpusNeeded: totalCorpusNeeded ?? this.totalCorpusNeeded,
      futureValueOfCurrentInvestment: futureValueOfCurrentInvestment ?? this.futureValueOfCurrentInvestment,
      corpusRequiredToBuild: corpusRequiredToBuild ?? this.corpusRequiredToBuild,
      monthlyInvestment: monthlyInvestment ?? this.monthlyInvestment,
      yearlyInvestment: yearlyInvestment ?? this.yearlyInvestment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        dob,
        retirementAge,
        lifeExpectancy,
        inflationRate,
        postRetirementReturnRate,
        preRetirementReturnRate,
        preRetirementReturnRatioVariation,
        monthlyExpensesVariation,
        currentMonthlyExpenses,
        currentSavings,
        periodForIncome,
        preRetirementReturnRateCalculated,
        monthlyExpensesAtRetirement,
        totalCorpusNeeded,
        futureValueOfCurrentInvestment,
        corpusRequiredToBuild,
        monthlyInvestment,
        yearlyInvestment,
        createdAt,
        updatedAt,
      ];
}

