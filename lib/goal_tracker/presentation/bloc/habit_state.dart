import 'package:equatable/equatable.dart';
import '../../domain/entities/habit.dart';

/// Base class for all habit states.
abstract class HabitState extends Equatable {
  const HabitState();

  @override
  List<Object?> get props => [];
}

/// State indicating that habits are currently being loaded.
class HabitsLoading extends HabitState {
  const HabitsLoading();
}

/// State indicating that habits have been successfully loaded.
class HabitsLoaded extends HabitState {
  final List<Habit> habits;
  final String? milestoneId; // Optional filter context
  final Map<String, bool> visibleFields;

  const HabitsLoaded(
    this.habits, {
    this.milestoneId,
    this.visibleFields = const {
      'name': true,
      'description': true,
      'milestoneName': false,
      'goalName': false,
      'rrule': false,
      'targetCompletions': false,
      'isActive': false,
    },
  });

  @override
  List<Object?> get props => [habits, milestoneId, visibleFields];
}

/// State indicating that an error occurred while loading habits.
class HabitsError extends HabitState {
  final String message;

  const HabitsError(this.message);

  @override
  List<Object?> get props => [message];
}
