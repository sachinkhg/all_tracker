import 'package:flutter_test/flutter_test.dart';

import 'package:all_tracker/trackers/goal_tracker/features/import_export_mappers.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/goal_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/milestone_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/task_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/habit_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/habit_completion_model.dart';

void main() {
  group('generic helpers', () {
    test('parseFlexibleDate and formatDateDdMmYyyy', () {
      final d1 = parseFlexibleDate('2025-01-31');
      final d2 = parseFlexibleDate('31/01/2025');
      expect(d1, isNotNull);
      expect(d2, isNotNull);
      expect(formatDateDdMmYyyy(DateTime(2025, 1, 31)), '31/01/2025');
    });

    test('normalizeContext and parseYesNo', () {
      expect(normalizeContext('work'), 'Work');
      expect(normalizeContext('unknown'), isNull);
      expect(parseYesNo('Yes'), true);
      expect(parseYesNo('0'), false);
      expect(parseYesNo('maybe'), isNull);
    });
  });

  group('backup mappers roundtrip', () {
    test('goal', () {
      final g = GoalModel(id: 'g', name: 'n');
      final json = goalToBackupJson(g);
      final back = goalFromBackupJson(json);
      expect(back.id, 'g');
      expect(back.name, 'n');
    });

    test('milestone', () {
      final m = MilestoneModel(id: 'm', name: 'n', goalId: 'g');
      final json = milestoneToBackupJson(m);
      final back = milestoneFromBackupJson(json);
      expect(back.id, 'm');
      expect(back.goalId, 'g');
    });

    test('task', () {
      final t = TaskModel(id: 't', name: 'n', milestoneId: 'm', goalId: 'g');
      final json = taskToBackupJson(t);
      final back = taskFromBackupJson(json);
      expect(back.id, 't');
      expect(back.goalId, 'g');
    });

    test('habit', () {
      final h = HabitModel(id: 'h', name: 'n', milestoneId: 'm', goalId: 'g', rrule: 'FREQ=DAILY');
      final json = habitToBackupJson(h);
      final back = habitFromBackupJson(json);
      expect(back.id, 'h');
      expect(back.rrule, 'FREQ=DAILY');
    });

    test('habit completion', () {
      final c = HabitCompletionModel(id: 'c', habitId: 'h', completionDate: DateTime(2025, 1, 1));
      final json = completionToBackupJson(c);
      final back = completionFromBackupJson(json);
      expect(back.id, 'c');
      expect(back.habitId, 'h');
    });
  });
}


