// lib/trackers/portfolio_tracker/domain/entities/redemption_log.dart
// Domain entity for Redemption Log

import 'package:equatable/equatable.dart';

/// Domain entity for Redemption Log.
///
/// Represents a redemption or withdrawal transaction for an investment master.
/// Tracks the details of each redemption including quantity, sell price, and amounts.
class RedemptionLog extends Equatable {
  /// Unique identifier for the redemption log (GUID recommended).
  final String id;

  /// Reference to the investment master this log belongs to.
  final String investmentId;

  /// Date when the redemption was made.
  final DateTime redemptionDate;

  /// Quantity of units redeemed (nullable).
  final double? quantity;

  /// Average sell price per unit (nullable).
  final double? averageSellPrice;

  /// Cost to sell or withdraw (fees, charges, etc.) (nullable).
  final double? costToSellOrWithdraw;

  /// Currency conversion amount (nullable, required if currency is not INR).
  final double? currencyConversionAmount;

  /// Timestamp of creation.
  final DateTime createdAt;

  /// Timestamp of last update.
  final DateTime updatedAt;

  /// Constructor for RedemptionLog.
  const RedemptionLog({
    required this.id,
    required this.investmentId,
    required this.redemptionDate,
    this.quantity,
    this.averageSellPrice,
    this.costToSellOrWithdraw,
    this.currencyConversionAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        investmentId,
        redemptionDate,
        quantity,
        averageSellPrice,
        costToSellOrWithdraw,
        currencyConversionAmount,
        createdAt,
        updatedAt,
      ];

  /// Creates a copy of this RedemptionLog with the given fields replaced.
  RedemptionLog copyWith({
    String? id,
    String? investmentId,
    DateTime? redemptionDate,
    double? quantity,
    double? averageSellPrice,
    double? costToSellOrWithdraw,
    double? currencyConversionAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RedemptionLog(
      id: id ?? this.id,
      investmentId: investmentId ?? this.investmentId,
      redemptionDate: redemptionDate ?? this.redemptionDate,
      quantity: quantity ?? this.quantity,
      averageSellPrice: averageSellPrice ?? this.averageSellPrice,
      costToSellOrWithdraw: costToSellOrWithdraw ?? this.costToSellOrWithdraw,
      currencyConversionAmount: currencyConversionAmount ?? this.currencyConversionAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculates the actual amount redeemed.
  /// Formula: (quantity * averageSellPrice) - costToSellOrWithdraw
  /// Returns null if required values are missing.
  double? calculateActualAmountRedeemed() {
    if (quantity == null || averageSellPrice == null) {
      return null;
    }
    final baseAmount = quantity! * averageSellPrice!;
    final cost = costToSellOrWithdraw ?? 0.0;
    return baseAmount - cost;
  }

  /// Calculates the amount in native currency (INR).
  /// If currency is INR, returns actualAmountRedeemed.
  /// Otherwise, returns actualAmountRedeemed * currencyConversionAmount.
  /// Returns null if required values are missing.
  double? calculateAmountInNativeCurrency(bool isInrCurrency) {
    final actualAmount = calculateActualAmountRedeemed();
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

