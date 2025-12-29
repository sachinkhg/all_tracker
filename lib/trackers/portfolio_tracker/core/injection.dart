// lib/trackers/portfolio_tracker/core/injection.dart
// Composition root: wires data -> repository -> usecases -> cubit

import 'package:hive_flutter/hive_flutter.dart';
import '../data/datasources/investment_master_local_data_source.dart';
import '../data/datasources/investment_log_local_data_source.dart';
import '../data/datasources/redemption_log_local_data_source.dart';
import '../data/datasources/google_sheets_data_source.dart';
import '../data/models/investment_master_model.dart';
import '../data/models/investment_log_model.dart';
import '../data/models/redemption_log_model.dart';
import '../data/repositories/investment_master_repository_impl.dart';
import '../data/repositories/investment_log_repository_impl.dart';
import '../data/repositories/redemption_log_repository_impl.dart';
import '../domain/usecases/investment_master/get_all_investment_masters.dart';
import '../domain/usecases/investment_master/get_investment_master_by_id.dart';
import '../domain/usecases/investment_master/create_investment_master.dart';
import '../domain/usecases/investment_master/update_investment_master.dart';
import '../domain/usecases/investment_master/delete_investment_master.dart';
import '../domain/usecases/investment_log/get_investment_logs_by_master.dart';
import '../domain/usecases/investment_log/get_investment_log_by_id.dart';
import '../domain/usecases/investment_log/create_investment_log.dart';
import '../domain/usecases/investment_log/update_investment_log.dart';
import '../domain/usecases/investment_log/delete_investment_log.dart';
import '../domain/usecases/redemption_log/get_redemption_logs_by_master.dart';
import '../domain/usecases/redemption_log/get_redemption_log_by_id.dart';
import '../domain/usecases/redemption_log/create_redemption_log.dart';
import '../domain/usecases/redemption_log/update_redemption_log.dart';
import '../domain/usecases/redemption_log/delete_redemption_log.dart';
import '../presentation/bloc/investment_master_cubit.dart';
import '../presentation/bloc/investment_log_cubit.dart';
import '../presentation/bloc/redemption_log_cubit.dart';
import '../presentation/bloc/portfolio_cubit.dart';
import '../../../../features/backup/data/datasources/google_auth_datasource.dart';
import 'constants.dart';

/// Factory that constructs a fully-wired [InvestmentMasterCubit].
///
/// Implementation details:
/// - This function performs an *eager, manual wiring* of concrete implementations for the feature.
/// - It assumes the Hive boxes have already been opened (typically in `main()`).
/// - All objects created here are plain Dart instances (no DI container used).
InvestmentMasterCubit createInvestmentMasterCubit() {
  // IMPORTANT: Hive.box must be already opened (open in main.dart).
  // During hot reload, boxes might not be open - check first
  if (!Hive.isBoxOpen(PortfolioTrackerConstants.investmentMastersBoxName)) {
    throw StateError(
      'Investment masters box is not open. This may happen during hot reload. '
      'Please restart the app to reinitialize Hive boxes.',
    );
  }
  final Box<InvestmentMasterModel> mastersBox =
      Hive.box<InvestmentMasterModel>(PortfolioTrackerConstants.investmentMastersBoxName);

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final mastersLocal = InvestmentMasterLocalDataSourceImpl(mastersBox);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final mastersRepo = InvestmentMasterRepositoryImpl(mastersLocal);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getAllMasters = GetAllInvestmentMasters(mastersRepo);
  final getMasterById = GetInvestmentMasterById(mastersRepo);
  final createMaster = CreateInvestmentMaster(mastersRepo);
  final updateMaster = UpdateInvestmentMaster(mastersRepo);
  final deleteMaster = DeleteInvestmentMaster(mastersRepo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  return InvestmentMasterCubit(
    getAll: getAllMasters,
    getById: getMasterById,
    create: createMaster,
    update: updateMaster,
    delete: deleteMaster,
  );
}

/// Factory that constructs a fully-wired [InvestmentLogCubit].
InvestmentLogCubit createInvestmentLogCubit() {
  if (!Hive.isBoxOpen(PortfolioTrackerConstants.investmentLogsBoxName)) {
    throw StateError(
      'Investment logs box is not open. This may happen during hot reload. '
      'Please restart the app to reinitialize Hive boxes.',
    );
  }
  final Box<InvestmentLogModel> logsBox =
      Hive.box<InvestmentLogModel>(PortfolioTrackerConstants.investmentLogsBoxName);

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final logsLocal = InvestmentLogLocalDataSourceImpl(logsBox);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final logsRepo = InvestmentLogRepositoryImpl(logsLocal);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getLogsByMaster = GetInvestmentLogsByMaster(logsRepo);
  final getLogById = GetInvestmentLogById(logsRepo);
  final createLog = CreateInvestmentLog(logsRepo);
  final updateLog = UpdateInvestmentLog(logsRepo);
  final deleteLog = DeleteInvestmentLog(logsRepo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  return InvestmentLogCubit(
    getByMaster: getLogsByMaster,
    getById: getLogById,
    create: createLog,
    update: updateLog,
    delete: deleteLog,
  );
}

/// Factory that constructs a fully-wired [RedemptionLogCubit].
RedemptionLogCubit createRedemptionLogCubit() {
  if (!Hive.isBoxOpen(PortfolioTrackerConstants.redemptionLogsBoxName)) {
    throw StateError(
      'Redemption logs box is not open. This may happen during hot reload. '
      'Please restart the app to reinitialize Hive boxes.',
    );
  }
  final Box<RedemptionLogModel> logsBox =
      Hive.box<RedemptionLogModel>(PortfolioTrackerConstants.redemptionLogsBoxName);

  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final logsLocal = RedemptionLogLocalDataSourceImpl(logsBox);

  // ---------------------------------------------------------------------------
  // Repository layer
  // ---------------------------------------------------------------------------
  final logsRepo = RedemptionLogRepositoryImpl(logsLocal);

  // ---------------------------------------------------------------------------
  // Use-cases (domain)
  // ---------------------------------------------------------------------------
  final getLogsByMaster = GetRedemptionLogsByMaster(logsRepo);
  final getLogById = GetRedemptionLogById(logsRepo);
  final createLog = CreateRedemptionLog(logsRepo);
  final updateLog = UpdateRedemptionLog(logsRepo);
  final deleteLog = DeleteRedemptionLog(logsRepo);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  return RedemptionLogCubit(
    getByMaster: getLogsByMaster,
    getById: getLogById,
    create: createLog,
    update: updateLog,
    delete: deleteLog,
  );
}

/// Factory that constructs a fully-wired [PortfolioCubit] (for Google Sheets POC).
///
/// This is kept separate from the investment tracking cubits as it serves
/// a different purpose (price fetching from Google Sheets).
PortfolioCubit createPortfolioCubit() {
  // ---------------------------------------------------------------------------
  // Data layer
  // ---------------------------------------------------------------------------
  final authDataSource = GoogleAuthDataSource();
  final sheetsDataSource = GoogleSheetsDataSource(authDataSource);

  // ---------------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------------
  return PortfolioCubit(sheetsDataSource);
}
