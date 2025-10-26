import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/goal_tracker/data/datasources/milestone_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/models/milestone_model.dart';
import 'package:all_tracker/goal_tracker/data/repositories/milestone_repository_impl.dart';
import 'package:all_tracker/goal_tracker/domain/entities/milestone.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/milestone/create_milestone.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/milestone/get_all_milestones.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/milestone/get_milestone_by_id.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/milestone/get_milestones_by_goal_id.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/milestone/update_milestone.dart';
import 'package:all_tracker/goal_tracker/domain/usecases/milestone/delete_milestone.dart';

import '../../../helpers/fake_hive_box.dart';

void main() {
  group('Milestone use cases', () {
    late FakeBox<MilestoneModel> box;
    late MilestoneLocalDataSourceImpl local;
    late MilestoneRepositoryImpl repo;

    late CreateMilestone create;
    late GetAllMilestones getAll;
    late GetMilestoneById getById;
    late GetMilestonesByGoalId getByGoal;
    late UpdateMilestone update;
    late DeleteMilestone delete;

    setUp(() {
      box = FakeBox<MilestoneModel>('milestones_box');
      local = MilestoneLocalDataSourceImpl(box);
      repo = MilestoneRepositoryImpl(local);
      create = CreateMilestone(repo);
      getAll = GetAllMilestones(repo);
      getById = GetMilestoneById(repo);
      getByGoal = GetMilestonesByGoalId(repo);
      update = UpdateMilestone(repo);
      delete = DeleteMilestone(repo);
    });

    test('create/get/update/delete and by goal flow', () async {
      final m = Milestone(id: 'm1', name: 'M', goalId: 'g1');
      await create(m);
      expect((await getById('m1'))?.name, 'M');
      expect((await getByGoal('g1')).length, 1);

      await update(Milestone(id: 'm1', name: 'Mx', goalId: 'g1'));
      expect((await getById('m1'))?.name, 'Mx');

      final all = await getAll();
      expect(all.length, 1);

      await delete('m1');
      expect(await getById('m1'), isNull);
    });
  });
}


