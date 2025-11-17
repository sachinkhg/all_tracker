import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/trackers/goal_tracker/data/datasources/goal_local_data_source.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/goal_model.dart';

import '../../helpers/fake_hive_box.dart';

void main() {
  group('GoalLocalDataSourceImpl', () {
    late FakeBox<GoalModel> box;
    late GoalLocalDataSourceImpl ds;

    setUp(() {
      box = FakeBox<GoalModel>('goals_box');
      ds = GoalLocalDataSourceImpl(box);
    });

    test('create and get by id', () async {
      final g = GoalModel(id: 'g1', name: 'Goal', description: 'd');
      await ds.createGoal(g);

      final fetched = await ds.getGoalById('g1');
      expect(fetched?.id, 'g1');
      expect((await ds.getAllGoals()).length, 1);
    });

    test('update overwrites and delete removes', () async {
      final g = GoalModel(id: 'g1', name: 'A');
      await ds.createGoal(g);

      await ds.updateGoal(GoalModel(id: 'g1', name: 'B'));
      expect((await ds.getGoalById('g1'))?.name, 'B');

      await ds.deleteGoal('g1');
      expect(await ds.getGoalById('g1'), isNull);
      expect((await ds.getAllGoals()).isEmpty, true);
    });
  });
}


