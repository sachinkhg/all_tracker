import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/trackers/goal_tracker/data/datasources/milestone_local_data_source.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/milestone_model.dart';

import '../../helpers/fake_hive_box.dart';

void main() {
  group('MilestoneLocalDataSourceImpl', () {
    late FakeBox<MilestoneModel> box;
    late MilestoneLocalDataSourceImpl ds;

    setUp(() {
      box = FakeBox<MilestoneModel>('milestones_box');
      ds = MilestoneLocalDataSourceImpl(box);
    });

    test('CRUD and filter by goalId', () async {
      final m1 = MilestoneModel(id: 'm1', name: 'M1', goalId: 'g1');
      final m2 = MilestoneModel(id: 'm2', name: 'M2', goalId: 'g2');
      await ds.createMilestone(m1);
      await ds.createMilestone(m2);

      expect((await ds.getMilestoneById('m1'))?.name, 'M1');
      expect((await ds.getAllMilestones()).length, 2);
      expect((await ds.getMilestonesByGoalId('g1')).map((e) => e.id), ['m1']);

      await ds.updateMilestone(MilestoneModel(id: 'm1', name: 'M1x', goalId: 'g1'));
      expect((await ds.getMilestoneById('m1'))?.name, 'M1x');

      await ds.deleteMilestone('m2');
      expect((await ds.getAllMilestones()).length, 1);
    });
  });
}


