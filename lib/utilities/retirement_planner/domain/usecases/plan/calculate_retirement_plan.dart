// ./lib/utilities/retirement_planner/domain/usecases/plan/calculate_retirement_plan.dart
/*
  purpose:
    - Encapsulates the "Calculate Retirement Plan" use case in the domain layer.
    - Implements all retirement calculation formulas (J, M, N, O, P, Q, R, S).
    
  Calculation Formulas:
    J = D - C (Period for which income is needed)
    M = G * H (Pre-Retirement Return Rate Calculated)
    Years until retirement = C - ((today() - B) / 365.25)
    N = K * pow(1 + E, yearsUntilRetirement) * I (Monthly Expenses at Retirement)
    O = (N * 12 * (1 - pow(1 + F, -J))) / F (Total Corpus Needed)
    P = L * pow(1 + M, yearsUntilRetirement) (Future Value of Current Investment)
    Q = O - P (Corpus Required to build)
    R = (Q * M) / ((pow(1 + M, yearsUntilRetirement) - 1) * 12) (Monthly Investment)
    S = R * 12 (Yearly Investment)
*/

import 'dart:math' as math;
import '../../entities/retirement_plan.dart';

/// Use case class responsible for calculating retirement plan metrics.
class CalculateRetirementPlan {
  /// Calculates all retirement plan metrics for the given plan.
  ///
  /// Returns a new RetirementPlan with all calculated fields populated.
  RetirementPlan call(RetirementPlan plan) {
    final now = DateTime.now();
    
    // Calculate years until retirement (with decimal precision)
    final yearsUntilRetirement = plan.retirementAge - 
        ((now.difference(plan.dob).inDays) / 365.25);
    
    // Validate: retirement age should be after current age
    if (yearsUntilRetirement <= 0) {
      throw ArgumentError('Retirement age must be after current age');
    }
    
    // Validate: life expectancy should be after retirement age
    if (plan.lifeExpectancy <= plan.retirementAge) {
      throw ArgumentError('Life expectancy must be after retirement age');
    }
    
    // J = D - C (Period for which income is needed)
    final periodForIncome = (plan.lifeExpectancy - plan.retirementAge).toDouble();
    
    // M = G * H (Pre-Retirement Return Rate Calculated)
    final preRetirementReturnRateCalculated = 
        plan.preRetirementReturnRate * plan.preRetirementReturnRatioVariation;
    
    // N = K * pow(1 + E, yearsUntilRetirement) * I (Monthly Expenses at Retirement)
    final monthlyExpensesAtRetirement = plan.currentMonthlyExpenses *
        math.pow(1 + plan.inflationRate, yearsUntilRetirement) *
        plan.monthlyExpensesVariation;
    
    // O = (N * 12 * (1 - pow(1 + F, -J))) / F (Total Corpus Needed)
    final totalCorpusNeeded = (monthlyExpensesAtRetirement * 12 *
        (1 - math.pow(1 + plan.postRetirementReturnRate, -periodForIncome))) /
        plan.postRetirementReturnRate;
    
    // P = L * pow(1 + M, yearsUntilRetirement) (Future Value of Current Investment)
    final futureValueOfCurrentInvestment = plan.currentSavings *
        math.pow(1 + preRetirementReturnRateCalculated, yearsUntilRetirement);
    
    // Q = O - P (Corpus Required to build)
    final corpusRequiredToBuild = totalCorpusNeeded - futureValueOfCurrentInvestment;
    
    // R = (Q * M) / ((pow(1 + M, yearsUntilRetirement) - 1) * 12) (Monthly Investment)
    final denominator = (math.pow(1 + preRetirementReturnRateCalculated, yearsUntilRetirement) - 1) * 12;
    final monthlyInvestment = corpusRequiredToBuild > 0 
        ? (corpusRequiredToBuild * preRetirementReturnRateCalculated) / denominator
        : 0.0;
    
    // S = R * 12 (Yearly Investment)
    final yearlyInvestment = monthlyInvestment * 12;
    
    return plan.copyWith(
      periodForIncome: periodForIncome,
      preRetirementReturnRateCalculated: preRetirementReturnRateCalculated,
      monthlyExpensesAtRetirement: monthlyExpensesAtRetirement,
      totalCorpusNeeded: totalCorpusNeeded,
      futureValueOfCurrentInvestment: futureValueOfCurrentInvestment,
      corpusRequiredToBuild: corpusRequiredToBuild,
      monthlyInvestment: monthlyInvestment,
      yearlyInvestment: yearlyInvestment,
    );
  }
}

