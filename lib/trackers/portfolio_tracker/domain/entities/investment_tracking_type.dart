// lib/trackers/portfolio_tracker/domain/entities/investment_tracking_type.dart
// Investment tracking type enum

/// Type of tracking for investments
enum InvestmentTrackingType {
  unit,
  amount;

  /// Display name for the tracking type
  String get displayName {
    switch (this) {
      case InvestmentTrackingType.unit:
        return 'Unit';
      case InvestmentTrackingType.amount:
        return 'Amount';
    }
  }
}

