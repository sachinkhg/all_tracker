import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/trackers/goal_tracker/data/repositories/habit_completion_repository_impl.dart';
import 'package:all_tracker/trackers/goal_tracker/data/datasources/habit_completion_local_data_source.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/habit_completion_model.dart';
import 'package:all_tracker/trackers/goal_tracker/domain/entities/habit_completion.dart';

import '../../helpers/fake_hive_box.dart';

void main() {
  group('HabitCompletionRepositoryImpl', () {
    late FakeBox<HabitCompletionModel> box;
    late HabitCompletionLocalDataSourceImpl local;
    late HabitCompletionRepositoryImpl repo;

    setUp(() {
      box = FakeBox<HabitCompletionModel>('habit_completions_box');
      local = HabitCompletionLocalDataSourceImpl(completionBox: box);
      repo = HabitCompletionRepositoryImpl(localDataSource: local);
    });

    test('create/get/delete and by habit/date range', () async {
      final d1 = DateTime(2025, 1, 10);
      final d2 = DateTime(2025, 1, 12);
      final c1 = HabitCompletion(id: 'c1', habitId: 'h1', completionDate: d1);
      final c2 = HabitCompletion(id: 'c2', habitId: 'h1', completionDate: d2);
      await repo.createCompletion(c1);
      await repo.createCompletion(c2);

      expect((await repo.getCompletionForDate('h1', d1))?.id, 'c1');
      expect((await repo.getCompletionsByHabitId('h1')).map((e) => e.id).toSet(), {'c1', 'c2'});

      final ranged = await repo.getCompletionsByDateRange('h1', DateTime(2025, 1, 9), DateTime(2025, 1, 11));
      expect(ranged.map((e) => e.id).toList(), ['c1']);

      await repo.deleteCompletion('c2');
      expect((await repo.getAllCompletions()).length, 1);
    });
  });
}


