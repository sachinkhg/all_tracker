import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/trackers/goal_tracker/data/repositories/task_repository_impl.dart';
import 'package:all_tracker/trackers/goal_tracker/data/datasources/task_local_data_source.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/task_model.dart';
import 'package:all_tracker/trackers/goal_tracker/domain/entities/task.dart';

import '../../helpers/fake_hive_box.dart';

void main() {
  group('TaskRepositoryImpl', () {
    late FakeBox<TaskModel> box;
    late TaskLocalDataSourceImpl local;
    late TaskRepositoryImpl repo;

    setUp(() {
      box = FakeBox<TaskModel>('tasks_box');
      local = TaskLocalDataSourceImpl(box);
      repo = TaskRepositoryImpl(local);
    });

    test('create/get/update/delete roundtrip', () async {
      final t = Task(id: 't1', name: 'T', milestoneId: 'm1', goalId: 'g1');
      await repo.createTask(t);
      expect((await repo.getTaskById('t1'))?.name, 'T');

      final all = await repo.getAllTasks();
      expect(all.length, 1);

      await repo.updateTask(Task(id: 't1', name: 'Tx', milestoneId: 'm1', goalId: 'g1'));
      expect((await repo.getTaskById('t1'))?.name, 'Tx');

      await repo.deleteTask('t1');
      expect(await repo.getTaskById('t1'), isNull);
    });
  });
}


