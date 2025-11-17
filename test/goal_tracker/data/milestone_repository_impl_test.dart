import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/trackers/goal_tracker/data/repositories/milestone_repository_impl.dart';
import 'package:all_tracker/trackers/goal_tracker/data/datasources/milestone_local_data_source.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/milestone_model.dart';
import 'package:all_tracker/trackers/goal_tracker/domain/entities/milestone.dart';

import '../../helpers/fake_hive_box.dart';

void main() {
  group('MilestoneRepositoryImpl', () {
    late FakeBox<MilestoneModel> box;
    late MilestoneLocalDataSourceImpl local;
    late MilestoneRepositoryImpl repo;

    setUp(() {
      box = FakeBox<MilestoneModel>('milestones_box');
      local = MilestoneLocalDataSourceImpl(box);
      repo = MilestoneRepositoryImpl(local);
    });

    test('create/get/update/delete roundtrip', () async {
      final m = Milestone(id: 'm1', name: 'M', goalId: 'g1');
      await repo.createMilestone(m);
      expect((await repo.getMilestoneById('m1'))?.name, 'M');

      final all = await repo.getAllMilestones();
      expect(all.length, 1);

      await repo.updateMilestone(Milestone(id: 'm1', name: 'Mx', goalId: 'g1'));
      expect((await repo.getMilestoneById('m1'))?.name, 'Mx');

      await repo.deleteMilestone('m1');
      expect(await repo.getMilestoneById('m1'), isNull);
    });
  });
}


