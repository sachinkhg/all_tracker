import 'package:hive_flutter/hive_flutter.dart';
import 'constants.dart';

/// Service for managing retirement planner default preferences.
///
/// Stores and retrieves advance input defaults:
/// - Inflation Rate (E)
/// - Post-Retirement Return Rate (F)
/// - Pre-Retirement Return Ratio Variation (H)
/// - Monthly Expenses Variation (I)
class RetirementPreferencesService {
  Box<dynamic>? _box;

  /// Initialize the preferences box.
  Future<void> init() async {
    if (!Hive.isBoxOpen(retirementPreferencesBoxName)) {
      _box = await Hive.openBox(retirementPreferencesBoxName);
    } else {
      _box = Hive.box(retirementPreferencesBoxName);
    }
  }

  Box<dynamic> get box {
    if (_box == null) {
      throw StateError('PreferencesService not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Get default inflation rate (E).
  double getInflationRate() {
    return (box.get('inflationRate') as double?) ?? defaultInflationRate;
  }

  /// Get default post-retirement return rate (F).
  double getPostRetirementReturnRate() {
    return (box.get('postRetirementReturnRate') as double?) ?? defaultPostRetirementReturnRate;
  }

  /// Get default pre-retirement return ratio variation (H).
  double getPreRetirementReturnRatioVariation() {
    return (box.get('preRetirementReturnRatioVariation') as double?) ?? 
        defaultPreRetirementReturnRatioVariation;
  }

  /// Get default monthly expenses variation (I).
  double getMonthlyExpensesVariation() {
    return (box.get('monthlyExpensesVariation') as double?) ?? defaultMonthlyExpensesVariation;
  }

  /// Get all defaults as a map.
  Map<String, double> getDefaults() {
    return {
      'inflationRate': getInflationRate(),
      'postRetirementReturnRate': getPostRetirementReturnRate(),
      'preRetirementReturnRatioVariation': getPreRetirementReturnRatioVariation(),
      'monthlyExpensesVariation': getMonthlyExpensesVariation(),
    };
  }

  /// Save default inflation rate (E).
  Future<void> saveInflationRate(double rate) async {
    await box.put('inflationRate', rate);
  }

  /// Save default post-retirement return rate (F).
  Future<void> savePostRetirementReturnRate(double rate) async {
    await box.put('postRetirementReturnRate', rate);
  }

  /// Save default pre-retirement return ratio variation (H).
  Future<void> savePreRetirementReturnRatioVariation(double variation) async {
    await box.put('preRetirementReturnRatioVariation', variation);
  }

  /// Save default monthly expenses variation (I).
  Future<void> saveMonthlyExpensesVariation(double variation) async {
    await box.put('monthlyExpensesVariation', variation);
  }

  /// Save all defaults at once.
  Future<void> saveDefaults({
    required double inflationRate,
    required double postRetirementReturnRate,
    required double preRetirementReturnRatioVariation,
    required double monthlyExpensesVariation,
  }) async {
    await box.put('inflationRate', inflationRate);
    await box.put('postRetirementReturnRate', postRetirementReturnRate);
    await box.put('preRetirementReturnRatioVariation', preRetirementReturnRatioVariation);
    await box.put('monthlyExpensesVariation', monthlyExpensesVariation);
  }
}

