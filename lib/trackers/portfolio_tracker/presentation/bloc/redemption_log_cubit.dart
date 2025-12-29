// lib/trackers/portfolio_tracker/presentation/bloc/redemption_log_cubit.dart
// Cubit for redemption log state management

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/redemption_log.dart';
import '../../domain/usecases/redemption_log/get_redemption_logs_by_master.dart';
import '../../domain/usecases/redemption_log/get_redemption_log_by_id.dart';
import '../../domain/usecases/redemption_log/create_redemption_log.dart';
import '../../domain/usecases/redemption_log/update_redemption_log.dart';
import '../../domain/usecases/redemption_log/delete_redemption_log.dart';
import '../bloc/redemption_log_state.dart';

/// Cubit for managing redemption log state
class RedemptionLogCubit extends Cubit<RedemptionLogState> {
  final GetRedemptionLogsByMaster getByMaster;
  final GetRedemptionLogById getById;
  final CreateRedemptionLog create;
  final UpdateRedemptionLog update;
  final DeleteRedemptionLog delete;

  RedemptionLogCubit({
    required this.getByMaster,
    required this.getById,
    required this.create,
    required this.update,
    required this.delete,
  }) : super(const RedemptionLogsInitial());

  /// Loads all redemption logs for a specific investment master.
  Future<void> loadRedemptionLogs(String investmentId) async {
    emit(const RedemptionLogsLoading());
    try {
      final logs = await getByMaster(investmentId);
      emit(RedemptionLogsLoaded(logs));
    } catch (e) {
      emit(RedemptionLogsError('Failed to load redemption logs: $e'));
    }
  }

  /// Gets a redemption log by its ID.
  Future<RedemptionLog?> getRedemptionLogById(String id) async {
    try {
      return await getById(id);
    } catch (e) {
      emit(RedemptionLogsError('Failed to get redemption log: $e'));
      return null;
    }
  }

  /// Creates a new redemption log.
  Future<void> createRedemptionLog({
    required String investmentId,
    required DateTime redemptionDate,
    double? quantity,
    double? averageSellPrice,
    double? costToSellOrWithdraw,
    double? currencyConversionAmount,
  }) async {
    try {
      final now = DateTime.now();
      final log = RedemptionLog(
        id: const Uuid().v4(),
        investmentId: investmentId,
        redemptionDate: redemptionDate,
        quantity: quantity,
        averageSellPrice: averageSellPrice,
        costToSellOrWithdraw: costToSellOrWithdraw,
        currencyConversionAmount: currencyConversionAmount,
        createdAt: now,
        updatedAt: now,
      );

      await create(log);
      await loadRedemptionLogs(investmentId); // Reload to refresh the list
    } catch (e) {
      emit(RedemptionLogsError('Failed to create redemption log: $e'));
    }
  }

  /// Updates an existing redemption log.
  Future<void> updateRedemptionLog(RedemptionLog log) async {
    try {
      final updated = log.copyWith(updatedAt: DateTime.now());
      await update(updated);
      await loadRedemptionLogs(log.investmentId); // Reload to refresh the list
    } catch (e) {
      emit(RedemptionLogsError('Failed to update redemption log: $e'));
    }
  }

  /// Deletes a redemption log.
  Future<void> deleteRedemptionLog(String id, String investmentId) async {
    try {
      await delete(id);
      await loadRedemptionLogs(investmentId); // Reload to refresh the list
    } catch (e) {
      emit(RedemptionLogsError('Failed to delete redemption log: $e'));
    }
  }
}

