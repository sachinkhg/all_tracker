import 'package:uuid/uuid.dart';
import '../../entities/habit_completion.dart';
import '../../repositories/habit_completion_repository.dart';
import '../../repositories/habit_repository.dart';
import '../../repositories/milestone_repository.dart';

/// Use case for toggling habit completion for a specific date.
///
/// This use case encapsulates the business logic for creating or deleting
/// a habit completion for a specific date. It also handles updating the
/// associated milestone's actualValue based on the habit's targetCompletions.
/// This is a critical business rule that ensures milestone progress is
/// automatically updated when habits are completed.
class ToggleCompletionForDate {
  final HabitCompletionRepository completionRepository;
  final HabitRepository habitRepository;
  final MilestoneRepository milestoneRepository;

  ToggleCompletionForDate({
    required this.completionRepository,
    required this.habitRepository,
    required this.milestoneRepository,
  });

  /// Toggles completion for a habit on a specific date.
  ///
  /// If a completion exists for the date, it will be deleted and the
  /// milestone's actualValue will be decremented. If no completion exists,
  /// a new one will be created and the milestone's actualValue will be
  /// incremented.
  Future<void> call(String habitId, DateTime date) async {
    // Normalize date to date-only (midnight UTC) to avoid timezone issues
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    // Check if completion already exists for this date
    final existingCompletion = await completionRepository.getCompletionForDate(
      habitId,
      normalizedDate,
    );

    // Get the habit to access milestoneId and targetCompletions
    final habit = await habitRepository.getHabitById(habitId);
    if (habit == null) {
      throw Exception('Habit with id $habitId not found');
    }

    // Get the milestone to update its actualValue
    final milestone = await milestoneRepository.getMilestoneById(habit.milestoneId);
    if (milestone == null) {
      throw Exception('Milestone with id ${habit.milestoneId} not found');
    }

    final contribution = habit.targetCompletions ?? 1;

    if (existingCompletion != null) {
      // Delete existing completion and decrement milestone progress
      await completionRepository.deleteCompletion(existingCompletion.id);
      
      // Update milestone actualValue
      final updatedMilestone = milestone.copyWith(
        actualValue: (milestone.actualValue ?? 0) - contribution,
      );
      await milestoneRepository.updateMilestone(updatedMilestone);
    } else {
      // Create new completion and increment milestone progress
      final completion = HabitCompletion(
        id: const Uuid().v4(),
        habitId: habitId,
        completionDate: normalizedDate,
      );
      await completionRepository.createCompletion(completion);
      
      // Update milestone actualValue
      final updatedMilestone = milestone.copyWith(
        actualValue: (milestone.actualValue ?? 0) + contribution,
      );
      await milestoneRepository.updateMilestone(updatedMilestone);
    }
  }
}
