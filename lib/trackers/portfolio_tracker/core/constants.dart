// lib/trackers/portfolio_tracker/core/constants.dart
// Constants for portfolio tracker feature

class PortfolioTrackerConstants {
  PortfolioTrackerConstants._();

  // Default sheet range (assumes Column A = tickers, Column B = prices)
  static const String defaultSheetName = 'Sheet1';
  static const String defaultTickerColumn = 'A';
  static const String defaultPriceColumn = 'B';

  // Hive box names
  static const String investmentMastersBoxName = 'investment_masters_box';
  static const String investmentLogsBoxName = 'investment_logs_box';
  static const String redemptionLogsBoxName = 'redemption_logs_box';
}

