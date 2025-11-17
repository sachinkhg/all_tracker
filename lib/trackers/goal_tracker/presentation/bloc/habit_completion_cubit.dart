/*
 * File: habit_completion_cubit.dart
 *
 * Purpose:
 * - Manages presentation state for HabitCompletion entities within the Habit feature.
 * - Loads, creates, deletes habit completions by delegating to domain use-cases.
 * - Handles the critical business rule of updating milestone progress when
 *   completions are toggled.
 * - Provides methods for calendar views and completion tracking.
 *
 * State & behavior notes:
 * - This cubit manages completion data and milestone progress updates atomically.
 * - The toggleCompletionForDate method is critical as it updates milestone.actualValue.
 * - Date normalization ensures timezone consistency.
 *
 * Developer guidance:
 * - Keep domain validation and persistence in the use-cases/repository; this
 *   cubit should orchestrate and transform results for UI consumption only.
 * - All completion operations must update milestone progress atomically.
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/habit_completion.dart';
import '../../domain/usecases/habit_completion/get_all_completions.dart';
import '../../domain/usecases/habit_completion/get_completions_by_habit_id.dart';
import '../../domain/usecases/habit_completion/get_completions_by_date_range.dart';
import '../../domain/usecases/habit_completion/create_completion.dart';
import '../../domain/usecases/habit_completion/delete_completion.dart';
import '../../domain/usecases/habit_completion/toggle_completion_for_date.dart';
import 'habit_completion_state.dart';

/// Cubit to manage HabitCompletion state.
class HabitCompletionCubit extends Cubit<HabitCompletionState> {
  final GetAllCompletions getAllCompletions;
  final GetCompletionsByHabitId getCompletionsByHabitId;
  final GetCompletionsByDateRange getCompletionsByDateRange;
  final CreateCompletion createCompletion;
  final DeleteCompletion deleteCompletion;
  final ToggleCompletionForDate toggleCompletion;

  // master copy of all completions fetched from the domain layer.
  List<HabitCompletion> _allCompletions = [];

  // Current filter context
  String? _currentHabitIdFilter;

  HabitCompletionCubit({
    required this.getAllCompletions,
    required this.getCompletionsByHabitId,
    required this.getCompletionsByDateRange,
    required this.createCompletion,
    required this.deleteCompletion,
    required this.toggleCompletion,
  }) : super(const CompletionsLoading());

  /// Load all habit completions from repository.
  Future<void> loadCompletions() async {
    try {
      emit(const CompletionsLoading());
      final data = await getAllCompletions();
      _allCompletions = data;
      emit(CompletionsLoaded(data));
    } catch (e) {
      emit(CompletionsError(e.toString()));
    }
  }

  /// Load completions for a specific habit.
  Future<void> loadCompletionsByHabitId(String habitId) async {
    try {
      emit(const CompletionsLoading());
      final data = await getCompletionsByHabitId(habitId);
      _currentHabitIdFilter = habitId;
      // Keep master list in sync so statistics methods reflect latest state
      _allCompletions = data;
      emit(CompletionsLoaded(data, habitId: habitId));
    } catch (e) {
      emit(CompletionsError(e.toString()));
    }
  }

  /// Load completions for a habit within a date range.
  Future<void> loadCompletionsByDateRange(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      emit(const CompletionsLoading());
      final data = await getCompletionsByDateRange(habitId, startDate, endDate);
      _currentHabitIdFilter = habitId;
      // Also refresh the master list for this habit so statistics reflect
      // the latest state immediately (streaks, total counts, etc.).
      try {
        final allForHabit = await getCompletionsByHabitId(habitId);
        _allCompletions = allForHabit;
      } catch (_) {
        // Non-fatal; UI still receives the ranged data below.
      }
      emit(CompletionsLoaded(data, habitId: habitId, startDate: startDate, endDate: endDate));
    } catch (e) {
      emit(CompletionsError(e.toString()));
    }
  }

  /// Toggle completion for a habit on a specific date.
  ///
  /// This is the critical method that handles the business rule:
  /// - If completion exists: delete it and decrement milestone.actualValue
  /// - If completion doesn't exist: create it and increment milestone.actualValue
  /// - The milestone progress update is handled atomically in the use case.
  Future<void> toggleCompletionForDate(String habitId, DateTime date) async {
    try {
      // Normalize date to date-only (midnight UTC) to avoid timezone issues
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      await toggleCompletion(habitId, normalizedDate);
      
      // Reload completions to reflect the change
      if (_currentHabitIdFilter == habitId) {
        await loadCompletionsByHabitId(habitId);
      } else {
        await loadCompletions();
      }
    } catch (e) {
      emit(CompletionsError(e.toString()));
    }
  }

  /// Create a new habit completion.
  ///
  /// Note: This method does NOT update milestone progress. Use toggleCompletionForDate
  /// instead for the complete business rule implementation.
  Future<void> addCompletion({
    required String habitId,
    required DateTime date,
    String? note,
  }) async {
    try {
      // Normalize date to date-only (midnight UTC) to avoid timezone issues
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      final completion = HabitCompletion(
        id: const Uuid().v4(),
        habitId: habitId,
        completionDate: normalizedDate,
        note: note,
      );

      await createCompletion(completion);
      
      // Reload completions to reflect the change
      if (_currentHabitIdFilter == habitId) {
        await loadCompletionsByHabitId(habitId);
      } else {
        await loadCompletions();
      }
    } catch (e) {
      emit(CompletionsError(e.toString()));
    }
  }

  /// Delete a habit completion.
  ///
  /// Note: This method does NOT update milestone progress. Use toggleCompletionForDate
  /// instead for the complete business rule implementation.
  Future<void> removeCompletion(String id) async {
    try {
      await deleteCompletion(id);
      
      // Reload completions to reflect the change
      if (_currentHabitIdFilter != null) {
        await loadCompletionsByHabitId(_currentHabitIdFilter!);
      } else {
        await loadCompletions();
      }
    } catch (e) {
      emit(CompletionsError(e.toString()));
    }
  }

  /// Check if a habit is completed on a specific date.
  bool isCompletedOnDate(String habitId, DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    return _allCompletions.any((completion) =>
        completion.habitId == habitId &&
        completion.completionDate.year == normalizedDate.year &&
        completion.completionDate.month == normalizedDate.month &&
        completion.completionDate.day == normalizedDate.day);
  }

  /// Get completion count for a habit.
  int getCompletionCount(String habitId) {
    return _allCompletions.where((completion) => completion.habitId == habitId).length;
  }

  /// Get completion count for a habit within a date range.
  int getCompletionCountInRange(String habitId, DateTime startDate, DateTime endDate) {
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    
    return _allCompletions.where((completion) {
      if (completion.habitId != habitId) return false;
      
      final completionDate = DateTime(
        completion.completionDate.year,
        completion.completionDate.month,
        completion.completionDate.day,
      );
      
      return completionDate.isAtSameMomentAs(normalizedStart) ||
             completionDate.isAtSameMomentAs(normalizedEnd) ||
             (completionDate.isAfter(normalizedStart) && completionDate.isBefore(normalizedEnd));
    }).length;
  }

  /// Get current streak for a habit (consecutive days with completions).
  int getCurrentStreak(String habitId) {
    final habitCompletions = _allCompletions
        .where((completion) => completion.habitId == habitId)
        .map((completion) => DateTime(
              completion.completionDate.year,
              completion.completionDate.month,
              completion.completionDate.day,
            ))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending (most recent first)

    if (habitCompletions.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    // Check if today is completed
    if (habitCompletions.any((date) => date.isAtSameMomentAs(todayNormalized))) {
      streak = 1;
    } else {
      // Check if yesterday is completed (streak might be broken)
      final yesterday = todayNormalized.subtract(const Duration(days: 1));
      if (habitCompletions.any((date) => date.isAtSameMomentAs(yesterday))) {
        streak = 1;
      } else {
        return 0; // No streak if today and yesterday are not completed
      }
    }

    // Count consecutive days going backwards
    DateTime currentDate = todayNormalized.subtract(const Duration(days: 1));
    while (habitCompletions.any((date) => date.isAtSameMomentAs(currentDate))) {
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
