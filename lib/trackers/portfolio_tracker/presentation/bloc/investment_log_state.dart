// lib/trackers/portfolio_tracker/presentation/bloc/investment_log_state.dart
// States for investment log feature

import 'package:equatable/equatable.dart';
import '../../domain/entities/investment_log.dart';

abstract class InvestmentLogState extends Equatable {
  const InvestmentLogState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no data loaded
class InvestmentLogsInitial extends InvestmentLogState {
  const InvestmentLogsInitial();
}

/// Loading state - fetching investment logs
class InvestmentLogsLoading extends InvestmentLogState {
  const InvestmentLogsLoading();
}

/// Success state - investment logs loaded successfully
class InvestmentLogsLoaded extends InvestmentLogState {
  final List<InvestmentLog> investmentLogs;

  const InvestmentLogsLoaded(this.investmentLogs);

  @override
  List<Object?> get props => [investmentLogs];
}

/// Error state - error occurred while fetching
class InvestmentLogsError extends InvestmentLogState {
  final String message;

  const InvestmentLogsError(this.message);

  @override
  List<Object?> get props => [message];
}

