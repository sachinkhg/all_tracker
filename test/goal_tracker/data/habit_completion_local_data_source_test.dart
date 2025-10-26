import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/goal_tracker/data/datasources/habit_completion_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/models/habit_completion_model.dart';

import '../../helpers/fake_hive_box.dart';

void main() {
  group('HabitCompletionLocalDataSourceImpl', () {
    late FakeBox<HabitCompletionModel> box;
    late HabitCompletionLocalDataSourceImpl ds;

    setUp(() {
      box = FakeBox<HabitCompletionModel>('habit_completions_box');
      ds = HabitCompletionLocalDataSourceImpl(completionBox: box);
    });

    test('CRUD, by habitId and by date range', () async {
      final d1 = DateTime(2025, 1, 10);
      final d2 = DateTime(2025, 1, 12);
      final c1 = HabitCompletionModel(id: 'c1', habitId: 'h1', completionDate: d1);
      final c2 = HabitCompletionModel(id: 'c2', habitId: 'h1', completionDate: d2);
      final c3 = HabitCompletionModel(id: 'c3', habitId: 'h2', completionDate: d2);
      await ds.createCompletion(c1);
      await ds.createCompletion(c2);
      await ds.createCompletion(c3);

      expect((await ds.getCompletionForDate('h1', d1))?.id, 'c1');
      expect((await ds.getCompletionsByHabitId('h1')).map((e) => e.id).toSet(), {'c1', 'c2'});

      final ranged = await ds.getCompletionsByHabitIdAndDateRange('h1', DateTime(2025, 1, 9), DateTime(2025, 1, 11));
      expect(ranged.map((e) => e.id).toList(), ['c1']);

      await ds.deleteCompletion('c2');
      expect((await ds.getAllCompletions()).length, 2);

      await ds.deleteCompletionsByHabitId('h2');
      expect((await ds.getAllCompletions()).map((e) => e.id).toSet(), {'c1'});
    });
  });
}


