import 'package:all_tracker/goal_tracker/domain/entities/goal.dart';
import 'package:all_tracker/goal_tracker/domain/entities/milestone.dart';
import 'package:all_tracker/goal_tracker/domain/entities/task.dart';
import 'package:all_tracker/goal_tracker/domain/entities/habit.dart';
import 'package:all_tracker/goal_tracker/domain/entities/habit_completion.dart';

class TestDataBuilders {
  static Goal goal({
    String id = 'g-1',
    String name = 'Goal 1',
    String description = 'Desc',
    DateTime? targetDate,
    String? context = 'Work',
    bool isCompleted = false,
  }) => Goal(
        id: id,
        name: name,
        description: description,
        targetDate: targetDate ?? DateTime(2025, 1, 1),
        context: context,
        isCompleted: isCompleted,
      );

  static Milestone milestone({
    String id = 'm-1',
    String name = 'Milestone 1',
    String description = 'M Desc',
    double? plannedValue = 10,
    double? actualValue = 0,
    DateTime? targetDate,
    String goalId = 'g-1',
  }) => Milestone(
        id: id,
        name: name,
        description: description,
        plannedValue: plannedValue,
        actualValue: actualValue,
        targetDate: targetDate ?? DateTime(2025, 2, 1),
        goalId: goalId,
      );

  static Task task({
    String id = 't-1',
    String name = 'Task 1',
    DateTime? targetDate,
    String milestoneId = 'm-1',
    String goalId = 'g-1',
    String status = 'To Do',
  }) => Task(
        id: id,
        name: name,
        targetDate: targetDate ?? DateTime(2025, 3, 1),
        milestoneId: milestoneId,
        goalId: goalId,
        status: status,
      );

  static Habit habit({
    String id = 'h-1',
    String name = 'Habit 1',
    String? description = 'H Desc',
    String milestoneId = 'm-1',
    String goalId = 'g-1',
    String rrule = 'FREQ=DAILY',
    int? targetCompletions = 1,
    bool isActive = true,
  }) => Habit(
        id: id,
        name: name,
        description: description,
        milestoneId: milestoneId,
        goalId: goalId,
        rrule: rrule,
        targetCompletions: targetCompletions,
        isActive: isActive,
      );

  static HabitCompletion completion({
    String id = 'c-1',
    String habitId = 'h-1',
    DateTime? date,
    String? note,
  }) => HabitCompletion(
        id: id,
        habitId: habitId,
        completionDate: date ?? DateTime(2025, 1, 10),
        note: note,
      );
}


