import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/trackers/goal_tracker/data/repositories/goal_repository_impl.dart';
import 'package:all_tracker/trackers/goal_tracker/data/datasources/goal_local_data_source.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/goal_model.dart';
import 'package:all_tracker/trackers/goal_tracker/domain/entities/goal.dart';

import '../../helpers/fake_hive_box.dart';

void main() {
  group('GoalRepositoryImpl', () {
    late FakeBox<GoalModel> box;
    late GoalLocalDataSourceImpl local;
    late GoalRepositoryImpl repo;

    setUp(() {
      box = FakeBox<GoalModel>('goals_box');
      local = GoalLocalDataSourceImpl(box);
      repo = GoalRepositoryImpl(local);
    });

    test('create/get/update/delete roundtrip', () async {
      final goal = Goal(id: 'g1', name: 'G', description: 'd', targetDate: null, context: 'Work');
      await repo.createGoal(goal);
      expect((await repo.getGoalById('g1'))?.name, 'G');

      final all = await repo.getAllGoals();
      expect(all.length, 1);

      await repo.updateGoal(Goal(id: 'g1', name: 'G2', description: 'd', targetDate: null, context: 'Work'));
      expect((await repo.getGoalById('g1'))?.name, 'G2');

      await repo.deleteGoal('g1');
      expect(await repo.getGoalById('g1'), isNull);
    });
  });
}


