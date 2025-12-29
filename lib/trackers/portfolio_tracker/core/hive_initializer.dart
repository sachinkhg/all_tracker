import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/hive/hive_module_initializer.dart';
import '../data/models/investment_master_model.dart';
import '../data/models/investment_log_model.dart';
import '../data/models/redemption_log_model.dart';
import 'constants.dart';

/// Hive initializer for the portfolio_tracker module.
///
/// This class handles registration of all Hive adapters and opening of all
/// Hive boxes required by the portfolio_tracker module. It implements the
/// HiveModuleInitializer interface so it can be discovered and called by
/// the central HiveInitializer.
class PortfolioTrackerHiveInitializer implements HiveModuleInitializer {
  @override
  Future<void> registerAdapters() async {
    // Register InvestmentMasterModel adapter (TypeId: 34)
    final investmentMasterAdapterId = InvestmentMasterModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(investmentMasterAdapterId)) {
      Hive.registerAdapter(InvestmentMasterModelAdapter());
    }

    // Register InvestmentLogModel adapter (TypeId: 35)
    final investmentLogAdapterId = InvestmentLogModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(investmentLogAdapterId)) {
      Hive.registerAdapter(InvestmentLogModelAdapter());
    }

    // Register RedemptionLogModel adapter (TypeId: 36)
    final redemptionLogAdapterId = RedemptionLogModelAdapter().typeId;
    if (!Hive.isAdapterRegistered(redemptionLogAdapterId)) {
      Hive.registerAdapter(RedemptionLogModelAdapter());
    }
  }

  @override
  Future<void> openBoxes() async {
    // Open investment masters box
    await Hive.openBox<InvestmentMasterModel>(
      PortfolioTrackerConstants.investmentMastersBoxName,
    );

    // Open investment logs box
    await Hive.openBox<InvestmentLogModel>(
      PortfolioTrackerConstants.investmentLogsBoxName,
    );

    // Open redemption logs box
    await Hive.openBox<RedemptionLogModel>(
      PortfolioTrackerConstants.redemptionLogsBoxName,
    );
  }
}

