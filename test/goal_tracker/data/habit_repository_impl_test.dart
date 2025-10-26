import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/goal_tracker/data/repositories/habit_repository_impl.dart';
import 'package:all_tracker/goal_tracker/data/datasources/habit_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/models/habit_model.dart';
import 'package:all_tracker/goal_tracker/domain/entities/habit.dart';

import '../../helpers/fake_hive_box.dart';

void main() {
  group('HabitRepositoryImpl', () {
    late FakeBox<HabitModel> box;
    late HabitLocalDataSourceImpl local;
    late HabitRepositoryImpl repo;

    setUp(() {
      box = FakeBox<HabitModel>('habits_box');
      local = HabitLocalDataSourceImpl(habitBox: box);
      repo = HabitRepositoryImpl(localDataSource: local);
    });

    test('create/get/update/delete roundtrip', () async {
      final h = Habit(id: 'h1', name: 'H', milestoneId: 'm1', goalId: 'g1', rrule: 'FREQ=DAILY');
      await repo.createHabit(h);
      expect((await repo.getHabitById('h1'))?.name, 'H');

      final all = await repo.getAllHabits();
      expect(all.length, 1);

      await repo.updateHabit(Habit(id: 'h1', name: 'Hx', milestoneId: 'm1', goalId: 'g1', rrule: 'FREQ=DAILY'));
      expect((await repo.getHabitById('h1'))?.name, 'Hx');

      await repo.deleteHabit('h1');
      expect(await repo.getHabitById('h1'), isNull);
    });
  });
}


