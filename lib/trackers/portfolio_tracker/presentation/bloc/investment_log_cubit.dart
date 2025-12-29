// lib/trackers/portfolio_tracker/presentation/bloc/investment_log_cubit.dart
// Cubit for investment log state management

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/investment_log.dart';
import '../../domain/usecases/investment_log/get_investment_logs_by_master.dart';
import '../../domain/usecases/investment_log/get_investment_log_by_id.dart';
import '../../domain/usecases/investment_log/create_investment_log.dart';
import '../../domain/usecases/investment_log/update_investment_log.dart';
import '../../domain/usecases/investment_log/delete_investment_log.dart';
import '../bloc/investment_log_state.dart';

/// Cubit for managing investment log state
class InvestmentLogCubit extends Cubit<InvestmentLogState> {
  final GetInvestmentLogsByMaster getByMaster;
  final GetInvestmentLogById getById;
  final CreateInvestmentLog create;
  final UpdateInvestmentLog update;
  final DeleteInvestmentLog delete;

  InvestmentLogCubit({
    required this.getByMaster,
    required this.getById,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(const InvestmentLogsInitial());

  /// Loads all investment logs for a specific investment master.
  Future<void> loadInvestmentLogs(String investmentId) async {
    emit(const InvestmentLogsLoading());
    try {
      final logs = await getByMaster(investmentId);
      emit(InvestmentLogsLoaded(logs));
    } catch (e) {
      emit(InvestmentLogsError('Failed to load investment logs: $e'));
    }
  }

  /// Gets an investment log by its ID.
  Future<InvestmentLog?> getInvestmentLogById(String id) async {
    try {
      return await getById(id);
    } catch (e) {
      emit(InvestmentLogsError('Failed to get investment log: $e'));
      return null;
    }
  }

  /// Creates a new investment log.
  Future<void> createInvestmentLog({
    required String investmentId,
    required DateTime purchaseDate,
    double? quantity,
    double? averageCostPrice,
    double? costToAcquire,
    double? currencyConversionAmount,
  }) async {
    try {
      final now = DateTime.now();
      final log = InvestmentLog(
        id: const Uuid().v4(),
        investmentId: investmentId,
        purchaseDate: purchaseDate,
        quantity: quantity,
        averageCostPrice: averageCostPrice,
        costToAcquire: costToAcquire,
        currencyConversionAmount: currencyConversionAmount,
        createdAt: now,
        updatedAt: now,
      );

      await create(log);
      await loadInvestmentLogs(investmentId); // Reload to refresh the list
    } catch (e) {
      emit(InvestmentLogsError('Failed to create investment log: $e'));
    }
  }

  /// Updates an existing investment log.
  Future<void> updateInvestmentLog(InvestmentLog log) async {
    try {
      final updated = log.copyWith(updatedAt: DateTime.now());
      await update(updated);
      await loadInvestmentLogs(log.investmentId); // Reload to refresh the list
    } catch (e) {
      emit(InvestmentLogsError('Failed to update investment log: $e'));
    }
  }

  /// Deletes an investment log.
  Future<void> deleteInvestmentLog(String id, String investmentId) async {
    try {
      await delete(id);
      await loadInvestmentLogs(investmentId); // Reload to refresh the list
    } catch (e) {
      emit(InvestmentLogsError('Failed to delete investment log: $e'));
    }
  }
}

