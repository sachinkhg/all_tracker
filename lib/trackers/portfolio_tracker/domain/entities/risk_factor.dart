// lib/trackers/portfolio_tracker/domain/entities/risk_factor.dart
// Risk factor enum

/// Risk levels for investments
enum RiskFactor {
  insane,
  high,
  medium,
  low;

  /// Display name for the risk factor
  String get displayName {
    switch (this) {
      case RiskFactor.insane:
        return 'Insane';
      case RiskFactor.high:
        return 'High';
      case RiskFactor.medium:
        return 'Medium';
      case RiskFactor.low:
        return 'Low';
    }
  }
}

