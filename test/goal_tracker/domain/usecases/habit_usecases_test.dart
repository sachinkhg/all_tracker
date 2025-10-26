import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/goal_tracker/data/datasources/habit_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/models/habit_model.dart';
import 'package:all_tracker/goal_tracker/data/repositories/habit_repository_impl.dart';
import 'package:all_tracker/goal_tracker/domain/entities/habit.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit/create_habit.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit/get_all_habits.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit/get_habit_by_id.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit/get_habits_by_milestone_id.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit/update_habit.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit/delete_habit.dart';

import '../../../helpers/fake_hive_box.dart';

void main() {
  group('Habit use cases', () {
    late FakeBox<HabitModel> box;
    late HabitLocalDataSourceImpl local;
    late HabitRepositoryImpl repo;

    late CreateHabit create;
    late GetAllHabits getAll;
    late GetHabitById getById;
    late GetHabitsByMilestoneId getByMilestone;
    late UpdateHabit update;
    late DeleteHabit delete;

    setUp(() {
      box = FakeBox<HabitModel>('habits_box');
      local = HabitLocalDataSourceImpl(habitBox: box);
      repo = HabitRepositoryImpl(localDataSource: local);
      create = CreateHabit(repository: repo);
      getAll = GetAllHabits(repository: repo);
      getById = GetHabitById(repository: repo);
      getByMilestone = GetHabitsByMilestoneId(repository: repo);
      update = UpdateHabit(repository: repo);
      delete = DeleteHabit(repository: repo);
    });

    test('create/get/update/delete and by milestone flow', () async {
      final h = Habit(id: 'h1', name: 'H', milestoneId: 'm1', goalId: 'g1', rrule: 'FREQ=DAILY');
      await create(h);
      expect((await getById('h1'))?.name, 'H');
      expect((await getByMilestone('m1')).length, 1);

      await update(Habit(id: 'h1', name: 'Hx', milestoneId: 'm1', goalId: 'g1', rrule: 'FREQ=DAILY'));
      expect((await getById('h1'))?.name, 'Hx');

      final all = await getAll();
      expect(all.length, 1);

      await delete('h1');
      expect(await getById('h1'), isNull);
    });
  });
}


