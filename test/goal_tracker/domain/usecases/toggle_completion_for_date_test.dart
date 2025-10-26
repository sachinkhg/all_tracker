import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/goal_tracker/data/datasources/habit_completion_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/datasources/habit_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/datasources/milestone_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/models/habit_completion_model.dart';
import 'package:all_tracker/goal_tracker/data/models/habit_model.dart';
import 'package:all_tracker/goal_tracker/data/models/milestone_model.dart';
import 'package:all_tracker/goal_tracker/data/repositories/habit_completion_repository_impl.dart';
import 'package:all_tracker/goal_tracker/data/repositories/habit_repository_impl.dart';
import 'package:all_tracker/goal_tracker/data/repositories/milestone_repository_impl.dart';
import 'package:all_tracker/goal_tracker/domain/entities/habit.dart';
import 'package:all_tracker/goal_tracker/domain/entities/milestone.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit_completion/toggle_completion_for_date.dart';

import '../../../helpers/fake_hive_box.dart';

void main() {
  group('ToggleCompletionForDate', () {
    late FakeBox<HabitCompletionModel> completionBox;
    late FakeBox<HabitModel> habitBox;
    late FakeBox<MilestoneModel> milestoneBox;

    late HabitCompletionRepositoryImpl completionRepo;
    late HabitRepositoryImpl habitRepo;
    late MilestoneRepositoryImpl milestoneRepo;

    late ToggleCompletionForDate toggle;

    setUp(() {
      completionBox = FakeBox<HabitCompletionModel>('habit_completions_box');
      habitBox = FakeBox<HabitModel>('habits_box');
      milestoneBox = FakeBox<MilestoneModel>('milestones_box');

      completionRepo = HabitCompletionRepositoryImpl(
        localDataSource: HabitCompletionLocalDataSourceImpl(completionBox: completionBox),
      );
      habitRepo = HabitRepositoryImpl(
        localDataSource: HabitLocalDataSourceImpl(habitBox: habitBox),
      );
      milestoneRepo = MilestoneRepositoryImpl(
        MilestoneLocalDataSourceImpl(milestoneBox),
      );

      toggle = ToggleCompletionForDate(
        completionRepository: completionRepo,
        habitRepository: habitRepo,
        milestoneRepository: milestoneRepo,
      );
    });

    test('creates completion and increments milestone actualValue; toggles back to decrement', () async {
      // Seed milestone and habit
      final m = Milestone(id: 'm1', name: 'M', goalId: 'g1', actualValue: 0);
      await milestoneRepo.createMilestone(m);
      final h = Habit(id: 'h1', name: 'H', milestoneId: 'm1', goalId: 'g1', rrule: 'FREQ=DAILY', targetCompletions: 2);
      await habitRepo.createHabit(h);

      final date = DateTime(2025, 1, 10);

      // First toggle -> create completion, +2
      await toggle('h1', date);
      final afterInc = await milestoneRepo.getMilestoneById('m1');
      expect(afterInc?.actualValue, 2);

      // Second toggle -> delete completion, -2
      await toggle('h1', date);
      final afterDec = await milestoneRepo.getMilestoneById('m1');
      expect(afterDec?.actualValue, 0);
    });
  });
}


