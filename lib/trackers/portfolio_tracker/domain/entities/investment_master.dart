// lib/trackers/portfolio_tracker/domain/entities/investment_master.dart
// Domain entity for Investment Master

import 'package:equatable/equatable.dart';
import 'investment_category.dart';
import 'investment_tracking_type.dart';
import 'investment_currency.dart';
import 'risk_factor.dart';

/// Domain entity for Investment Master.
///
/// Represents a master investment record that tracks the overall investment
/// configuration and metadata. The actual investment amounts are tracked
/// through InvestmentLog and RedemptionLog entities.
class InvestmentMaster extends Equatable {
  /// Unique identifier for the investment master (GUID recommended).
  final String id;

  /// Short name or ticker symbol for the investment (unique).
  final String shortName;

  /// Full name or description of the investment.
  final String name;

  /// Category of the investment.
  final InvestmentCategory investmentCategory;

  /// Type of tracking (Unit or Amount).
  final InvestmentTrackingType investmentTrackingType;

  /// Currency of the investment.
  final InvestmentCurrency investmentCurrency;

  /// Risk factor associated with the investment.
  final RiskFactor riskFactor;

  /// Timestamp of creation.
  final DateTime createdAt;

  /// Timestamp of last update.
  final DateTime updatedAt;

  /// Constructor for InvestmentMaster.
  const InvestmentMaster({
    required this.id,
    required this.shortName,
    required this.name,
    required this.investmentCategory,
    required this.investmentTrackingType,
    required this.investmentCurrency,
    required this.riskFactor,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        shortName,
        name,
        investmentCategory,
        investmentTrackingType,
        investmentCurrency,
        riskFactor,
        createdAt,
        updatedAt,
      ];

  /// Creates a copy of this InvestmentMaster with the given fields replaced.
  InvestmentMaster copyWith({
    String? id,
    String? shortName,
    String? name,
    InvestmentCategory? investmentCategory,
    InvestmentTrackingType? investmentTrackingType,
    InvestmentCurrency? investmentCurrency,
    RiskFactor? riskFactor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvestmentMaster(
      id: id ?? this.id,
      shortName: shortName ?? this.shortName,
      name: name ?? this.name,
      investmentCategory: investmentCategory ?? this.investmentCategory,
      investmentTrackingType: investmentTrackingType ?? this.investmentTrackingType,
      investmentCurrency: investmentCurrency ?? this.investmentCurrency,
      riskFactor: riskFactor ?? this.riskFactor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns whether the investment is active.
  /// This is a derived field calculated from activeAmount > 0.
  /// The actual calculation should be done in the calculation helper
  /// using investment logs. This getter is provided for convenience
  /// when activeAmount is already calculated.
  bool isActive(double activeAmount) {
    return activeAmount > 0;
  }
}

