// lib/trackers/portfolio_tracker/domain/entities/investment_currency.dart
// Investment currency enum

/// Currency types for investments
enum InvestmentCurrency {
  inr,
  usd;

  /// Display name for the currency
  String get displayName {
    switch (this) {
      case InvestmentCurrency.inr:
        return 'INR';
      case InvestmentCurrency.usd:
        return 'USD';
    }
  }

  /// Symbol for the currency
  String get symbol {
    switch (this) {
      case InvestmentCurrency.inr:
        return '₹';
      case InvestmentCurrency.usd:
        return '\$';
    }
  }
}

