// lib/trackers/portfolio_tracker/features/calculations/investment_calculations.dart
// Centralized calculation helpers for investment derived fields

import '../../domain/entities/investment_master.dart';
import '../../domain/entities/investment_log.dart';
import '../../domain/entities/redemption_log.dart';
import '../../domain/entities/investment_currency.dart';

/// Centralized calculation helpers for investment derived fields.
///
/// All derived field calculations should be performed through these helpers
/// to ensure consistency and maintainability.
class InvestmentCalculations {
  InvestmentCalculations._();

  /// Calculates investment totals for an investment master.
  ///
  /// Returns a map with:
  /// - totalInvested: Sum of amountInNativeCurrency from all investment logs
  /// - totalRedeemed: Sum of amountInNativeCurrency from all redemption logs
  /// - activeAmount: totalInvested - totalRedeemed
  static Map<String, double> calculateInvestmentTotals({
    required InvestmentMaster investmentMaster,
    required List<InvestmentLog> investmentLogs,
    required List<RedemptionLog> redemptionLogs,
  }) {
    final isInrCurrency = investmentMaster.investmentCurrency == InvestmentCurrency.inr;

    // Calculate total invested
    double totalInvested = 0.0;
    for (final log in investmentLogs) {
      final amount = log.calculateAmountInNativeCurrency(isInrCurrency);
      if (amount != null) {
        totalInvested += amount;
      }
    }

    // Calculate total redeemed
    double totalRedeemed = 0.0;
    for (final log in redemptionLogs) {
      final amount = log.calculateAmountInNativeCurrency(isInrCurrency);
      if (amount != null) {
        totalRedeemed += amount;
      }
    }

    // Calculate active amount
    final activeAmount = totalInvested - totalRedeemed;

    return {
      'totalInvested': totalInvested,
      'totalRedeemed': totalRedeemed,
      'activeAmount': activeAmount,
    };
  }

  /// Determines if an investment is active based on active amount.
  ///
  /// Returns true if activeAmount > 0, false otherwise.
  static bool calculateIsActive(double activeAmount) {
    return activeAmount > 0;
  }

  /// Calculates the actual amount invested for an investment log.
  ///
  /// Formula: (quantity * averageCostPrice) + costToAcquire
  /// Returns null if required values are missing.
  static double? calculateActualAmountInvested({
    required double? quantity,
    required double? averageCostPrice,
    required double? costToAcquire,
  }) {
    if (quantity == null || averageCostPrice == null) {
      return null;
    }
    final baseAmount = quantity * averageCostPrice;
    final cost = costToAcquire ?? 0.0;
    return baseAmount + cost;
  }

  /// Calculates the actual amount redeemed for a redemption log.
  ///
  /// Formula: (quantity * averageSellPrice) - costToSellOrWithdraw
  /// Returns null if required values are missing.
  static double? calculateActualAmountRedeemed({
    required double? quantity,
    required double? averageSellPrice,
    required double? costToSellOrWithdraw,
  }) {
    if (quantity == null || averageSellPrice == null) {
      return null;
    }
    final baseAmount = quantity * averageSellPrice;
    final cost = costToSellOrWithdraw ?? 0.0;
    return baseAmount - cost;
  }

  /// Calculates the amount in native currency (INR) for an investment log.
  ///
  /// If currency is INR, returns actualAmountInvested.
  /// Otherwise, returns actualAmountInvested * currencyConversionAmount.
  /// Returns null if required values are missing.
  static double? calculateAmountInNativeCurrencyForInvestment({
    required double? actualAmountInvested,
    required bool isInrCurrency,
    required double? currencyConversionAmount,
  }) {
    if (actualAmountInvested == null) {
      return null;
    }

    if (isInrCurrency) {
      return actualAmountInvested;
    }

    if (currencyConversionAmount == null) {
      return null;
    }

    return actualAmountInvested * currencyConversionAmount;
  }

  /// Calculates the amount in native currency (INR) for a redemption log.
  ///
  /// If currency is INR, returns actualAmountRedeemed.
  /// Otherwise, returns actualAmountRedeemed * currencyConversionAmount.
  /// Returns null if required values are missing.
  static double? calculateAmountInNativeCurrencyForRedemption({
    required double? actualAmountRedeemed,
    required bool isInrCurrency,
    required double? currencyConversionAmount,
  }) {
    if (actualAmountRedeemed == null) {
      return null;
    }

    if (isInrCurrency) {
      return actualAmountRedeemed;
    }

    if (currencyConversionAmount == null) {
      return null;
    }

    return actualAmountRedeemed * currencyConversionAmount;
  }

  /// Validates that redemption quantity does not exceed active investment quantity.
  ///
  /// Returns true if redemption is valid, false otherwise.
  static bool validateRedemptionQuantity({
    required double? redemptionQuantity,
    required double activeQuantity,
  }) {
    if (redemptionQuantity == null) {
      return false;
    }
    return redemptionQuantity <= activeQuantity;
  }

  /// Validates that redemption amount does not exceed active investment amount.
  ///
  /// Returns true if redemption is valid, false otherwise.
  static bool validateRedemptionAmount({
    required double? redemptionAmount,
    required double activeAmount,
  }) {
    if (redemptionAmount == null) {
      return false;
    }
    return redemptionAmount <= activeAmount;
  }

  /// Calculates active quantity for an investment master.
  ///
  /// Sum of all investment log quantities minus sum of all redemption log quantities.
  static double calculateActiveQuantity({
    required List<InvestmentLog> investmentLogs,
    required List<RedemptionLog> redemptionLogs,
  }) {
    double totalInvestedQuantity = 0.0;
    for (final log in investmentLogs) {
      if (log.quantity != null) {
        totalInvestedQuantity += log.quantity!;
      }
    }

    double totalRedeemedQuantity = 0.0;
    for (final log in redemptionLogs) {
      if (log.quantity != null) {
        totalRedeemedQuantity += log.quantity!;
      }
    }

    return totalInvestedQuantity - totalRedeemedQuantity;
  }
}

