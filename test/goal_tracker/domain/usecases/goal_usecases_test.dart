import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/goal_tracker/data/datasources/goal_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/models/goal_model.dart';
import 'package:all_tracker/goal_tracker/data/repositories/goal_repository_impl.dart';
import 'package:all_tracker/goal_tracker/domain/entities/goal.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/goal/create_goal.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/goal/get_all_goals.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/goal/get_goal_by_id.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/goal/update_goal.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/goal/delete_goal.dart';

import '../../../helpers/fake_hive_box.dart';

void main() {
  group('Goal use cases', () {
    late FakeBox<GoalModel> box;
    late GoalLocalDataSourceImpl local;
    late GoalRepositoryImpl repo;

    late CreateGoal create;
    late GetAllGoals getAll;
    late GetGoalById getById;
    late UpdateGoal update;
    late DeleteGoal delete;

    setUp(() {
      box = FakeBox<GoalModel>('goals_box');
      local = GoalLocalDataSourceImpl(box);
      repo = GoalRepositoryImpl(local);
      create = CreateGoal(repo);
      getAll = GetAllGoals(repo);
      getById = GetGoalById(repo);
      update = UpdateGoal(repo);
      delete = DeleteGoal(repo);
    });

    test('create/get/update/delete flow', () async {
      final g = Goal(id: 'g1', name: 'G', description: 'd', context: 'Work');
      await create(g);
      expect((await getById('g1'))?.name, 'G');

      await update(Goal(id: 'g1', name: 'G2', description: 'd', context: 'Work'));
      expect((await getById('g1'))?.name, 'G2');

      final all = await getAll();
      expect(all.length, 1);

      await delete('g1');
      expect(await getById('g1'), isNull);
    });
  });
}


