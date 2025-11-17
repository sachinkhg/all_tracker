import 'package:all_tracker/trackers/goal_tracker/data/models/goal_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/milestone_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/task_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/habit_model.dart';
import 'package:all_tracker/trackers/goal_tracker/data/models/habit_completion_model.dart';
import 'package:all_tracker/trackers/goal_tracker/core/constants.dart';

// ---------- Generic helpers (shared by import/export UIs and tests) ----------

String formatDateDdMmYyyy(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

DateTime? parseFlexibleDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  try {
    return DateTime.parse(s);
  } catch (_) {}
  final parts = s.split(RegExp(r'[\/\-\.\s]'));
  if (parts.length >= 3) {
    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      if (year > 0 && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    } catch (_) {}
  }
  return null;
}

String? normalizeContext(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;
  for (final opt in kContextOptions) {
    if (opt.toLowerCase() == s.toLowerCase()) return opt;
  }
  return null;
}

bool? parseYesNo(dynamic raw) {
  if (raw == null) return null;
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final s = raw.toString().trim().toLowerCase();
  if (s.isEmpty) return null;
  const trueValues = {'yes', 'y', 'true', '1', 't'};
  const falseValues = {'no', 'n', 'false', '0', 'f'};
  if (trueValues.contains(s)) return true;
  if (falseValues.contains(s)) return false;
  try {
    final v = int.parse(s);
    return v != 0;
  } catch (_) {}
  return null;
}

// ---------- Backup/restore JSON mappers (pure) ----------

Map<String, dynamic> goalToBackupJson(GoalModel g) => {
      'id': g.id,
      'name': g.name,
      'description': g.description,
      'targetDate': g.targetDate?.toUtc().toIso8601String(),
      'context': g.context,
      'isCompleted': g.isCompleted,
    };

GoalModel goalFromBackupJson(Map<String, dynamic> m) => GoalModel(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String?,
      targetDate:
          (m['targetDate'] != null) ? DateTime.tryParse(m['targetDate']) : null,
      context: m['context'] as String?,
      isCompleted: (m['isCompleted'] as bool?) ?? false,
    );

Map<String, dynamic> milestoneToBackupJson(MilestoneModel m) => {
      'id': m.id,
      'name': m.name,
      'description': m.description,
      'plannedValue': m.plannedValue,
      'actualValue': m.actualValue,
      'targetDate': m.targetDate?.toUtc().toIso8601String(),
      'goalId': m.goalId,
    };

MilestoneModel milestoneFromBackupJson(Map<String, dynamic> m) => MilestoneModel(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String?,
      plannedValue: (m['plannedValue'] as num?)?.toDouble(),
      actualValue: (m['actualValue'] as num?)?.toDouble(),
      targetDate:
          (m['targetDate'] != null) ? DateTime.tryParse(m['targetDate']) : null,
      goalId: m['goalId'] as String,
    );

Map<String, dynamic> taskToBackupJson(TaskModel t) => {
      'id': t.id,
      'name': t.name,
      'targetDate': t.targetDate?.toUtc().toIso8601String(),
      'milestoneId': t.milestoneId,
      'goalId': t.goalId,
      'status': t.status,
    };

TaskModel taskFromBackupJson(Map<String, dynamic> m) => TaskModel(
      id: m['id'] as String,
      name: m['name'] as String,
      targetDate:
          (m['targetDate'] != null) ? DateTime.tryParse(m['targetDate']) : null,
      milestoneId: m['milestoneId'] as String,
      goalId: m['goalId'] as String,
      status: (m['status'] as String?) ?? 'To Do',
    );

Map<String, dynamic> habitToBackupJson(HabitModel h) => {
      'id': h.id,
      'name': h.name,
      'description': h.description,
      'milestoneId': h.milestoneId,
      'goalId': h.goalId,
      'rrule': h.rrule,
      'targetCompletions': h.targetCompletions,
      'isActive': h.isActive,
    };

HabitModel habitFromBackupJson(Map<String, dynamic> m) => HabitModel(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String?,
      milestoneId: m['milestoneId'] as String,
      goalId: m['goalId'] as String,
      rrule: m['rrule'] as String,
      targetCompletions: (m['targetCompletions'] as num?)?.toInt(),
      isActive: (m['isActive'] as bool?) ?? true,
    );

Map<String, dynamic> completionToBackupJson(HabitCompletionModel c) => {
      'id': c.id,
      'habitId': c.habitId,
      'completionDate': c.completionDate.toUtc().toIso8601String(),
      'note': c.note,
    };

HabitCompletionModel completionFromBackupJson(Map<String, dynamic> m) =>
    HabitCompletionModel(
      id: m['id'] as String,
      habitId: m['habitId'] as String,
      completionDate:
          DateTime.tryParse(m['completionDate'] as String) ?? DateTime.now(),
      note: m['note'] as String?,
    );


