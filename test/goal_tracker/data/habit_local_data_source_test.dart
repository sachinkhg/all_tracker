import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/trackers/goal_tracker/data/datasources/habit_local_data_source.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/habit_model.dart';

import '../../helpers/fake_hive_box.dart';

void main() {
  group('HabitLocalDataSourceImpl', () {
    late FakeBox<HabitModel> box;
    late HabitLocalDataSourceImpl ds;

    setUp(() {
      box = FakeBox<HabitModel>('habits_box');
      ds = HabitLocalDataSourceImpl(habitBox: box);
    });

    test('CRUD and filter by milestoneId', () async {
      final h1 = HabitModel(id: 'h1', name: 'H1', milestoneId: 'm1', goalId: 'g1', rrule: 'FREQ=DAILY');
      final h2 = HabitModel(id: 'h2', name: 'H2', milestoneId: 'm2', goalId: 'g1', rrule: 'FREQ=DAILY');
      await ds.createHabit(h1);
      await ds.createHabit(h2);

      expect((await ds.getHabitById('h1'))?.name, 'H1');
      expect((await ds.getHabitsByMilestoneId('m1')).map((e) => e.id), ['h1']);

      await ds.updateHabit(HabitModel(id: 'h1', name: 'H1x', milestoneId: 'm1', goalId: 'g1', rrule: 'FREQ=DAILY'));
      expect((await ds.getHabitById('h1'))?.name, 'H1x');

      await ds.deleteHabit('h2');
      expect((await ds.getAllHabits()).length, 1);
    });
  });
}


