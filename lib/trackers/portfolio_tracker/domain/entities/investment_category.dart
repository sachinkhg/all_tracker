// lib/trackers/portfolio_tracker/domain/entities/investment_category.dart
// Investment category enum

/// Categories for investment types
enum InvestmentCategory {
  cryptocurrency,
  usShare,
  indianShare,
  mutualFundEquity,
  mutualFundDebt,
  goldBond,
  nationalPensionScheme,
  publicProvidentFund,
  guaranteedInvestment,
  employeeProvidentFund,
  employeePensionScheme,
  emergencyAccount;

  /// Display name for the category
  String get displayName {
    switch (this) {
      case InvestmentCategory.cryptocurrency:
        return 'Cryptocurrency';
      case InvestmentCategory.usShare:
        return 'US Share';
      case InvestmentCategory.indianShare:
        return 'Indian Share';
      case InvestmentCategory.mutualFundEquity:
        return 'Mutual Fund - Equity';
      case InvestmentCategory.mutualFundDebt:
        return 'Mutual Fund - Debt';
      case InvestmentCategory.goldBond:
        return 'Gold Bond';
      case InvestmentCategory.nationalPensionScheme:
        return 'National Pension Scheme';
      case InvestmentCategory.publicProvidentFund:
        return 'Public Provident Fund';
      case InvestmentCategory.guaranteedInvestment:
        return 'Guaranteed Investment';
      case InvestmentCategory.employeeProvidentFund:
        return 'Employee Provident Fund';
      case InvestmentCategory.employeePensionScheme:
        return 'Employee Pension Scheme';
      case InvestmentCategory.emergencyAccount:
        return 'Emergency Account';
    }
  }
}

