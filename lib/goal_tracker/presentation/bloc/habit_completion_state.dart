import 'package:equatable/equatable.dart';
import '../../domain/entities/habit_completion.dart';

/// Base class for all habit completion states.
abstract class HabitCompletionState extends Equatable {
  const HabitCompletionState();

  @override
  List<Object?> get props => [];
}

/// State indicating that habit completions are currently being loaded.
class CompletionsLoading extends HabitCompletionState {
  const CompletionsLoading();
}

/// State indicating that habit completions have been successfully loaded.
class CompletionsLoaded extends HabitCompletionState {
  final List<HabitCompletion> completions;
  final String? habitId; // Optional filter context
  final DateTime? startDate; // Optional date range filter
  final DateTime? endDate; // Optional date range filter

  const CompletionsLoaded(
    this.completions, {
    this.habitId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [completions, habitId, startDate, endDate];
}

/// State indicating that an error occurred while loading habit completions.
class CompletionsError extends HabitCompletionState {
  final String message;

  const CompletionsError(this.message);

  @override
  List<Object?> get props => [message];
}
