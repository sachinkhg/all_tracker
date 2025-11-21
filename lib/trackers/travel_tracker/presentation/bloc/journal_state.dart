import 'package:equatable/equatable.dart';
import '../../domain/entities/journal_entry.dart';

/// Base state for journal operations.
abstract class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object?> get props => [];
}

/// Loading state.
class JournalLoading extends JournalState {}

/// Loaded state with entries.
class JournalLoaded extends JournalState {
  final List<JournalEntry> entries;
  final bool isRefreshing;

  const JournalLoaded(this.entries, {this.isRefreshing = false});

  @override
  List<Object?> get props => [entries, isRefreshing];
}

/// Error state.
class JournalError extends JournalState {
  final String message;

  const JournalError(this.message);

  @override
  List<Object?> get props => [message];
}

