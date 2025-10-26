import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/goal_tracker/data/datasources/task_local_data_source.dart';
import 'package:all_tracker/goal_tracker/data/models/task_model.dart';

import '../../helpers/fake_hive_box.dart';

void main() {
  group('TaskLocalDataSourceImpl', () {
    late FakeBox<TaskModel> box;
    late TaskLocalDataSourceImpl ds;

    setUp(() {
      box = FakeBox<TaskModel>('tasks_box');
      ds = TaskLocalDataSourceImpl(box);
    });

    test('CRUD and filters by milestoneId/goalId', () async {
      final t1 = TaskModel(id: 't1', name: 'T1', milestoneId: 'm1', goalId: 'g1');
      final t2 = TaskModel(id: 't2', name: 'T2', milestoneId: 'm2', goalId: 'g1');
      final t3 = TaskModel(id: 't3', name: 'T3', milestoneId: 'm1', goalId: 'g2');
      await ds.createTask(t1);
      await ds.createTask(t2);
      await ds.createTask(t3);

      expect((await ds.getTaskById('t2'))?.name, 'T2');
      expect((await ds.getTasksByMilestoneId('m1')).map((e) => e.id).toSet(), {'t1', 't3'});
      expect((await ds.getTasksByGoalId('g1')).map((e) => e.id).toSet(), {'t1', 't2'});

      await ds.updateTask(TaskModel(id: 't1', name: 'T1x', milestoneId: 'm1', goalId: 'g1'));
      expect((await ds.getTaskById('t1'))?.name, 'T1x');

      await ds.deleteTask('t3');
      expect((await ds.getAllTasks()).length, 2);
    });
  });
}


