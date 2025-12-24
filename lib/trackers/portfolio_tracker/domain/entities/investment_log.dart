// lib/trackers/portfolio_tracker/domain/entities/investment_log.dart
// Domain entity for Investment Log

import 'package:equatable/equatable.dart';

/// Domain entity for Investment Log.
///
/// Represents a purchase or investment transaction for an investment master.
/// Tracks the details of each investment including quantity, cost, and amounts.
class InvestmentLog extends Equatable {
  /// Unique identifier for the investment log (GUID recommended).
  final String id;

  /// Reference to the investment master this log belongs to.
  final String investmentId;

  /// Date when the investment was made.
  final DateTime purchaseDate;

  /// Quantity of units purchased (nullable, required if tracking type is Unit).
  final double? quantity;

  /// Average cost price per unit (nullable).
  final double? averageCostPrice;

  /// Additional cost to acquire (fees, charges, etc.) (nullable).
  final double? costToAcquire;

  /// Currency conversion amount (nullable, required if currency is not INR).
  final double? currencyConversionAmount;

  /// Timestamp of creation.
  final DateTime createdAt;

  /// Timestamp of last update.
  final DateTime updatedAt;

  /// Constructor for InvestmentLog.
  const InvestmentLog({
    required this.id,
    required this.investmentId,
    required this.purchaseDate,
    this.quantity,
    this.averageCostPrice,
    this.costToAcquire,
    this.currencyConversionAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        investmentId,
        purchaseDate,
        quantity,
        averageCostPrice,
        costToAcquire,
        currencyConversionAmount,
        createdAt,
        updatedAt,
      ];

  /// Creates a copy of this InvestmentLog with the given fields replaced.
  InvestmentLog copyWith({
    String? id,
    String? investmentId,
    DateTime? purchaseDate,
    double? quantity,
    double? averageCostPrice,
    double? costToAcquire,
    double? currencyConversionAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvestmentLog(
      id: id ?? this.id,
      investmentId: investmentId ?? this.investmentId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      quantity: quantity ?? this.quantity,
      averageCostPrice: averageCostPrice ?? this.averageCostPrice,
      costToAcquire: costToAcquire ?? this.costToAcquire,
      currencyConversionAmount: currencyConversionAmount ?? this.currencyConversionAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculates the actual amount invested.
  /// Formula: (quantity * averageCostPrice) + costToAcquire
  /// Returns null if required values are missing.
  double? calculateActualAmountInvested() {
    if (quantity == null || averageCostPrice == null) {
      return null;
    }
    final baseAmount = quantity! * averageCostPrice!;
    final cost = costToAcquire ?? 0.0;
    return baseAmount + cost;
  }

  /// Calculates the amount in native currency (INR).
  /// If currency is INR, returns actualAmountInvested.
  /// Otherwise, returns actualAmountInvested * currencyConversionAmount.
  /// Returns null if required values are missing.
  double? calculateAmountInNativeCurrency(bool isInrCurrency) {
    final actualAmount = calculateActualAmountInvested();
    if (actualAmount == null) {
      return null;
    }

    if (isInrCurrency) {
      return actualAmount;
    }

    if (currencyConversionAmount == null) {
      return null;
    }

    return actualAmount * currencyConversionAmount!;
  }
}

