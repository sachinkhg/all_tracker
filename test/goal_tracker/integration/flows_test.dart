import 'package:flutter_test/flutter_test.dart';

import 'package:all_tracker/goal_tracker/data/datasources/goal_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/datasources/milestone_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/datasources/task_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/datasources/habit_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/datasources/habit_completion_local_data_source.dart';

import 'package:all_tracker/goal_tracker/data/models/goal_model.dart';
import 'package:all_tracker/goal_tracker/data/models/milestone_model.dart';
import 'package:all_tracker/goal_tracker/data/models/task_model.dart';
import 'package:all_tracker/goal_tracker/data/models/habit_model.dart';
import 'package:all_tracker/goal_tracker/data/models/habit_completion_model.dart';

import 'package:all_tracker/goal_tracker/data/repositories/goal_repository_impl.dart';
import 'package:all_tracker/goal_tracker/data/repositories/milestone_repository_impl.dart';
import 'package:all_tracker/goal_tracker/data/repositories/task_repository_impl.dart';
import 'package:all_tracker/goal_tracker/data/repositories/habit_repository_impl.dart';
import 'package:all_tracker/goal_tracker/data/repositories/habit_completion_repository_impl.dart';

import 'package:all_tracker/goal_tracker/domain/entities/goal.dart';
import 'package:all_tracker/goal_tracker/domain/entities/milestone.dart';
import 'package:all_tracker/goal_tracker/domain/entities/task.dart';
import 'package:all_tracker/goal_tracker/domain/entities/habit.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit_completion/toggle_completion_for_date.dart';

import '../../helpers/fake_hive_box.dart';

void main() {
  test('End-to-end flow: goal->milestone->task->habit and toggle completion', () async {
    // In-memory boxes
    final goalBox = FakeBox<GoalModel>('goals_box');
    final milestoneBox = FakeBox<MilestoneModel>('milestones_box');
    final taskBox = FakeBox<TaskModel>('tasks_box');
    final habitBox = FakeBox<HabitModel>('habits_box');
    final completionBox = FakeBox<HabitCompletionModel>('habit_completions_box');

    // Data sources
    final goalLocal = GoalLocalDataSourceImpl(goalBox);
    final milestoneLocal = MilestoneLocalDataSourceImpl(milestoneBox);
    final taskLocal = TaskLocalDataSourceImpl(taskBox);
    final habitLocal = HabitLocalDataSourceImpl(habitBox: habitBox);
    final completionLocal = HabitCompletionLocalDataSourceImpl(completionBox: completionBox);

    // Repositories
    final goalRepo = GoalRepositoryImpl(goalLocal);
    final milestoneRepo = MilestoneRepositoryImpl(milestoneLocal);
    final taskRepo = TaskRepositoryImpl(taskLocal);
    final habitRepo = HabitRepositoryImpl(localDataSource: habitLocal);
    final completionRepo = HabitCompletionRepositoryImpl(localDataSource: completionLocal);

    // Create a Goal
    final goal = Goal(id: 'g1', name: 'G', description: 'd', context: 'Work');
    await goalRepo.createGoal(goal);
    expect((await goalRepo.getAllGoals()).length, 1);

    // Create a Milestone under Goal
    final milestone = Milestone(id: 'm1', name: 'M', goalId: 'g1', actualValue: 0);
    await milestoneRepo.createMilestone(milestone);
    expect((await milestoneRepo.getMilestonesByGoalId('g1')).length, 1);

    // Create a Task under Milestone (and goal)
    final task = Task(id: 't1', name: 'T', milestoneId: 'm1', goalId: 'g1');
    await taskRepo.createTask(task);
    expect((await taskRepo.getTasksByMilestoneId('m1')).length, 1);

    // Create a Habit under Milestone
    final habit = Habit(id: 'h1', name: 'H', milestoneId: 'm1', goalId: 'g1', rrule: 'FREQ=DAILY', targetCompletions: 1);
    await habitRepo.createHabit(habit);
    expect((await habitRepo.getHabitsByMilestoneId('m1')).length, 1);

    // Toggle completion and assert milestone progress updates
    final toggle = ToggleCompletionForDate(
      completionRepository: completionRepo,
      habitRepository: habitRepo,
      milestoneRepository: milestoneRepo,
    );
    final date = DateTime(2025, 1, 10);

    await toggle('h1', date);
    expect((await milestoneRepo.getMilestoneById('m1'))?.actualValue, 1);

    await toggle('h1', date);
    expect((await milestoneRepo.getMilestoneById('m1'))?.actualValue, 0);
  });
}


