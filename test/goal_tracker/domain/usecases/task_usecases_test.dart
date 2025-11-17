import 'package:flutter_test/flutter_test.dart';
import 'package:all_tracker/trackers/goal_tracker/data/datasources/task_local_data_source.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/task_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/repositories/task_repository_impl.dart';
import 'package:all_tracker/trackers/goal_tracker/domain/entities/task.dart';
import 'package:all_tracker/trackers/goal_tracker/domain/usecases/task/create_task.dart';
import 'package:all_tracker/trackers/goal_tracker/domain/usecases/task/get_all_tasks.dart';
import 'package:all_tracker/trackers/goal_tracker/domain/usecases/task/get_task_by_id.dart';
import 'package:all_tracker/trackers/goal_tracker/domain/usecases/task/get_tasks_by_milestone_id.dart';
import 'package:all_tracker/trackers/goal_tracker/domain/usecases/task/update_task.dart';
import 'package:all_tracker/trackers/goal_tracker/domain/usecases/task/delete_task.dart';

import '../../../helpers/fake_hive_box.dart';

void main() {
  group('Task use cases', () {
    late FakeBox<TaskModel> box;
    late TaskLocalDataSourceImpl local;
    late TaskRepositoryImpl repo;

    late CreateTask create;
    late GetAllTasks getAll;
    late GetTaskById getById;
    late GetTasksByMilestoneId getByMilestone;
    late UpdateTask update;
    late DeleteTask delete;

    setUp(() {
      box = FakeBox<TaskModel>('tasks_box');
      local = TaskLocalDataSourceImpl(box);
      repo = TaskRepositoryImpl(local);
      create = CreateTask(repo);
      getAll = GetAllTasks(repo);
      getById = GetTaskById(repo);
      getByMilestone = GetTasksByMilestoneId(repo);
      update = UpdateTask(repo);
      delete = DeleteTask(repo);
    });

    test('create/get/update/delete and by milestone flow', () async {
      final t = Task(id: 't1', name: 'T', milestoneId: 'm1', goalId: 'g1');
      await create(t);
      expect((await getById('t1'))?.name, 'T');
      expect((await getByMilestone('m1')).length, 1);

      await update(Task(id: 't1', name: 'Tx', milestoneId: 'm1', goalId: 'g1'));
      expect((await getById('t1'))?.name, 'Tx');

      final all = await getAll();
      expect(all.length, 1);

      await delete('t1');
      expect(await getById('t1'), isNull);
    });
  });
}


