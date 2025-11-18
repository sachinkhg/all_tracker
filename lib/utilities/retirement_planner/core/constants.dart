// lib/utilities/retirement_planner/core/constants.dart

/// ---------------------------------------------------------------------------
/// Retirement Planner Constants
/// ---------------------------------------------------------------------------
///
/// Purpose:
/// - Constants specific to the retirement planner module.
/// - Box names, default values, and module-specific configuration.

/// Hive box name for retirement plan persistence.
const String retirementPlanBoxName = 'retirement_plan_box';

/// Hive box name for retirement preferences persistence.
const String retirementPreferencesBoxName = 'retirement_preferences_box';

/// Default inflation rate (5.5% from Example 1)
const double defaultInflationRate = 0.055;

/// Default post-retirement return rate (6.0% from Example 1)
const double defaultPostRetirementReturnRate = 0.06;

/// Default pre-retirement return ratio variation (1.0 from Example 1)
const double defaultPreRetirementReturnRatioVariation = 1.0;

/// Default monthly expenses variation (1.0 from Example 1)
const double defaultMonthlyExpensesVariation = 1.0;

