import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/goal_tracker/data/datasources/habit_completion_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/models/habit_completion_model.dart';
import 'package:all_tracker/goal_tracker/data/repositories/habit_completion_repository_impl.dart';
import 'package:all_tracker/goal_tracker/domain/entities/habit_completion.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit_completion/create_completion.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit_completion/get_all_completions.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit_completion/get_completions_by_habit_id.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit_completion/get_completions_by_date_range.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/habit_completion/delete_completion.dart';

import '../../../helpers/fake_hive_box.dart';

void main() {
  group('HabitCompletion use cases', () {
    late FakeBox<HabitCompletionModel> box;
    late HabitCompletionLocalDataSourceImpl local;
    late HabitCompletionRepositoryImpl repo;

    late CreateCompletion create;
    late GetAllCompletions getAll;
    late GetCompletionsByHabitId getByHabit;
    late GetCompletionsByDateRange getByRange;
    late DeleteCompletion delete;

    setUp(() {
      box = FakeBox<HabitCompletionModel>('habit_completions_box');
      local = HabitCompletionLocalDataSourceImpl(completionBox: box);
      repo = HabitCompletionRepositoryImpl(localDataSource: local);
      create = CreateCompletion(repository: repo);
      getAll = GetAllCompletions(repository: repo);
      getByHabit = GetCompletionsByHabitId(repository: repo);
      getByRange = GetCompletionsByDateRange(repository: repo);
      delete = DeleteCompletion(repository: repo);
    });

    test('create/get/delete and by habit/date range flow', () async {
      final d1 = DateTime(2025, 1, 10);
      final d2 = DateTime(2025, 1, 12);
      final c1 = HabitCompletion(id: 'c1', habitId: 'h1', completionDate: d1);
      final c2 = HabitCompletion(id: 'c2', habitId: 'h1', completionDate: d2);
      await create(c1);
      await create(c2);

      expect((await getByHabit('h1')).length, 2);
      expect((await getByRange('h1', DateTime(2025, 1, 9), DateTime(2025, 1, 11))).length, 1);

      await delete('c2');
      expect((await getAll()).length, 1);
    });
  });
}


