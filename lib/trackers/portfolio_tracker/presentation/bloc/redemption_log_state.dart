// lib/trackers/portfolio_tracker/presentation/bloc/redemption_log_state.dart
// States for redemption log feature

import 'package:equatable/equatable.dart';
import '../../domain/entities/redemption_log.dart';

abstract class RedemptionLogState extends Equatable {
  const RedemptionLogState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no data loaded
class RedemptionLogsInitial extends RedemptionLogState {
  const RedemptionLogsInitial();
}

/// Loading state - fetching redemption logs
class RedemptionLogsLoading extends RedemptionLogState {
  const RedemptionLogsLoading();
}

/// Success state - redemption logs loaded successfully
class RedemptionLogsLoaded extends RedemptionLogState {
  final List<RedemptionLog> redemptionLogs;

  const RedemptionLogsLoaded(this.redemptionLogs);

  @override
  List<Object?> get props => [redemptionLogs];
}

/// Error state - error occurred while fetching
class RedemptionLogsError extends RedemptionLogState {
  final String message;

  const RedemptionLogsError(this.message);

  @override
  List<Object?> get props => [message];
}

