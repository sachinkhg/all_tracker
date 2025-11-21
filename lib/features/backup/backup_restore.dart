import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

import '../../trackers/goal_tracker/core/constants.dart';
import '../../trackers/goal_tracker/data/models/goal_model.dart';
import '../../trackers/goal_tracker/data/models/milestone_model.dart';
import '../../trackers/goal_tracker/data/models/task_model.dart';
import '../../trackers/goal_tracker/data/models/habit_model.dart';
import '../../trackers/goal_tracker/data/models/habit_completion_model.dart';

/// Create a JSON-based backup of all Hive boxes and save as a .zip file.
Future<String?> createBackupZip(BuildContext context) async {
  try {
    final archive = Archive();

    // Metadata
    final metadata = <String, dynamic>{
      'backup_version': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    archive.addFile(ArchiveFile.string('metadata.json', jsonEncode(metadata)));

    // Helper to add JSON file to archive
    void addJson(String name, Object data) {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      archive.addFile(ArchiveFile.string(name, jsonStr));
    }

    // Data boxes
    final goalsBox = Hive.box<GoalModel>(goalBoxName);
    final goals = goalsBox.values.map((g) => {
          'id': g.id,
          'name': g.name,
          'description': g.description,
          'targetDate': g.targetDate?.toUtc().toIso8601String(),
          'context': g.context,
          'isCompleted': g.isCompleted,
        }).toList();
    addJson('goals.json', goals);

    final milestonesBox = Hive.box<MilestoneModel>(milestoneBoxName);
    final milestones = milestonesBox.values.map((m) => {
          'id': m.id,
          'name': m.name,
          'description': m.description,
          'plannedValue': m.plannedValue,
          'actualValue': m.actualValue,
          'targetDate': m.targetDate?.toUtc().toIso8601String(),
          'goalId': m.goalId,
        }).toList();
    addJson('milestones.json', milestones);

    final tasksBox = Hive.box<TaskModel>(taskBoxName);
    final tasks = tasksBox.values.map((t) => {
          'id': t.id,
          'name': t.name,
          'targetDate': t.targetDate?.toUtc().toIso8601String(),
          'milestoneId': t.milestoneId,
          'goalId': t.goalId,
          'status': t.status,
        }).toList();
    addJson('tasks.json', tasks);

    final habitsBox = Hive.box<HabitModel>(habitBoxName);
    final habits = habitsBox.values.map((h) => {
          'id': h.id,
          'name': h.name,
          'description': h.description,
          'milestoneId': h.milestoneId,
          'goalId': h.goalId,
          'rrule': h.rrule,
          'targetCompletions': h.targetCompletions,
          'isActive': h.isActive,
        }).toList();
    addJson('habits.json', habits);

    final completionsBox = Hive.box<HabitCompletionModel>(habitCompletionBoxName);
    final completions = completionsBox.values.map((c) => {
          'id': c.id,
          'habitId': c.habitId,
          'completionDate': c.completionDate.toUtc().toIso8601String(),
          'note': c.note,
        }).toList();
    addJson('habit_completions.json', completions);

    // Preferences (no need to add a directory explicitly; using paths creates folders)
    // view_preferences_box stores JSON strings as values keyed by canonical keys
    final viewPrefsBox = Hive.box(viewPreferencesBoxName);
    final viewPrefsMap = <String, String>{};
    for (final key in viewPrefsBox.keys) {
      final val = viewPrefsBox.get(key);
      if (val is String) viewPrefsMap[key.toString()] = val;
    }
    addJson('preferences/view_preferences.json', viewPrefsMap);

    final filterPrefsBox = Hive.box(filterPreferencesBoxName);
    final filterPrefsMap = <String, dynamic>{};
    for (final key in filterPrefsBox.keys) {
      filterPrefsMap[key.toString()] = filterPrefsBox.get(key);
    }
    addJson('preferences/filter_preferences.json', filterPrefsMap);

    final sortPrefsBox = Hive.box(sortPreferencesBoxName);
    final sortPrefsMap = <String, dynamic>{};
    for (final key in sortPrefsBox.keys) {
      sortPrefsMap[key.toString()] = sortPrefsBox.get(key);
    }
    addJson('preferences/sort_preferences.json', sortPrefsMap);

    // Theme prefs
    final themeBox = Hive.box(themePreferencesBoxName);
    final themePrefs = <String, dynamic>{
      'theme_key': themeBox.get('theme_key'),
      'font_key': themeBox.get('font_key'),
      'is_dark': themeBox.get('is_dark'),
    };
    addJson('preferences/theme_preferences.json', themePrefs);

    // Encode archive
    final encoder = ZipEncoder();
    final zippedBytes = Uint8List.fromList(encoder.encode(archive)!);

    final suggested = 'all_tracker_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.zip';

    // Try desktop-like save dialog
    try {
      final FileSaveLocation? saveLoc = await getSaveLocation(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'zip',
            extensions: ['zip'],
            // iOS requires UTIs; include common identifiers for ZIP archives
            uniformTypeIdentifiers: ['com.pkware.zip-archive', 'public.zip-archive'],
            mimeTypes: ['application/zip'],
          ),
        ],
        suggestedName: suggested,
      );
      if (saveLoc != null) {
        final out = XFile.fromData(zippedBytes, mimeType: 'application/zip', name: suggested);
        await out.saveTo(saveLoc.path);
        return saveLoc.path;
      }
    } catch (_) {}

    // Android save-as via platform channel (same channel as existing export helpers). Fallback to documents + share.
    try {
      final path = await _androidSaveFileCompat(zippedBytes, suggested);
      if (path != null) return path;
    } catch (_) {}

    final docs = await getApplicationDocumentsDirectory();
    final fallbackPath = p.join(docs.path, suggested);
    final xf = XFile.fromData(zippedBytes, mimeType: 'application/zip', name: suggested);
    await xf.saveTo(fallbackPath);
    try {
      await Share.shareXFiles([XFile(fallbackPath)], text: 'All Tracker backup');
    } catch (_) {}
    return fallbackPath;
  } catch (e, st) {
    debugPrint('Backup failed: $e\n$st');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup failed')));
    return null;
  }
}

/// Restore from a previously created JSON + Zip backup.
Future<void> restoreFromBackupZip(BuildContext context) async {
  try {
    const XTypeGroup zipGroup = XTypeGroup(
      label: 'zip',
      extensions: ['zip'],
      // iOS requires UTIs; include common identifiers for ZIP archives
      uniformTypeIdentifiers: ['com.pkware.zip-archive', 'public.zip-archive'],
      mimeTypes: ['application/zip'],
    );
    final XFile? picked = await openFile(acceptedTypeGroups: <XTypeGroup>[zipGroup]);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    Map<String, dynamic>? readJson(String name) {
      final file = archive.firstWhere((f) => f.name == name, orElse: () => ArchiveFile('', 0, Uint8List(0)));
      if (file.name.isEmpty || file.size == 0) return null;
      final content = utf8.decode(file.content as List<int>);
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    }

    List<dynamic>? readJsonList(String name) {
      final file = archive.firstWhere((f) => f.name == name, orElse: () => ArchiveFile('', 0, Uint8List(0)));
      if (file.name.isEmpty || file.size == 0) return null;
      final content = utf8.decode(file.content as List<int>);
      final decoded = jsonDecode(content);
      if (decoded is List) return decoded;
      return null;
    }

    // Parse data lists
    final goals = readJsonList('goals.json') ?? [];
    final milestones = readJsonList('milestones.json') ?? [];
    final tasks = readJsonList('tasks.json') ?? [];
    final habits = readJsonList('habits.json') ?? [];
    final completions = readJsonList('habit_completions.json') ?? [];

    // Clear boxes before restore
    await Hive.box<GoalModel>(goalBoxName).clear();
    await Hive.box<MilestoneModel>(milestoneBoxName).clear();
    await Hive.box<TaskModel>(taskBoxName).clear();
    await Hive.box<HabitModel>(habitBoxName).clear();
    await Hive.box<HabitCompletionModel>(habitCompletionBoxName).clear();

    // Repopulate in dependency order
    final goalBox = Hive.box<GoalModel>(goalBoxName);
    for (final g in goals) {
      final m = g as Map<String, dynamic>;
      final model = GoalModel(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        targetDate: (m['targetDate'] != null) ? DateTime.tryParse(m['targetDate']) : null,
        context: m['context'] as String?,
        isCompleted: (m['isCompleted'] as bool?) ?? false,
      );
      await goalBox.put(model.id, model);
    }

    final milestoneBox = Hive.box<MilestoneModel>(milestoneBoxName);
    for (final ms in milestones) {
      final m = ms as Map<String, dynamic>;
      final model = MilestoneModel(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        plannedValue: (m['plannedValue'] as num?)?.toDouble(),
        actualValue: (m['actualValue'] as num?)?.toDouble(),
        targetDate: (m['targetDate'] != null) ? DateTime.tryParse(m['targetDate']) : null,
        goalId: m['goalId'] as String,
      );
      await milestoneBox.put(model.id, model);
    }

    final taskBox = Hive.box<TaskModel>(taskBoxName);
    for (final t in tasks) {
      final m = t as Map<String, dynamic>;
      final model = TaskModel(
        id: m['id'] as String,
        name: m['name'] as String,
        targetDate: (m['targetDate'] != null) ? DateTime.tryParse(m['targetDate']) : null,
        milestoneId: m['milestoneId'] as String,
        goalId: m['goalId'] as String,
        status: (m['status'] as String?) ?? 'To Do',
      );
      await taskBox.put(model.id, model);
    }

    final habitBox = Hive.box<HabitModel>(habitBoxName);
    for (final h in habits) {
      final m = h as Map<String, dynamic>;
      final model = HabitModel(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        milestoneId: m['milestoneId'] as String,
        goalId: m['goalId'] as String,
        rrule: m['rrule'] as String,
        targetCompletions: (m['targetCompletions'] as num?)?.toInt(),
        isActive: (m['isActive'] as bool?) ?? true,
      );
      await habitBox.put(model.id, model);
    }

    final completionBox = Hive.box<HabitCompletionModel>(habitCompletionBoxName);
    for (final c in completions) {
      final m = c as Map<String, dynamic>;
      final model = HabitCompletionModel(
        id: m['id'] as String,
        habitId: m['habitId'] as String,
        completionDate: DateTime.tryParse(m['completionDate'] as String) ?? DateTime.now(),
        note: m['note'] as String?,
      );
      await completionBox.put(model.id, model);
    }

    // Preferences
    final viewPrefs = readJson('preferences/view_preferences.json') ?? {};
    final filterPrefs = readJson('preferences/filter_preferences.json') ?? {};
    final sortPrefs = readJson('preferences/sort_preferences.json') ?? {};
    final themePrefs = readJson('preferences/theme_preferences.json') ?? {};

    final viewBox = Hive.box(viewPreferencesBoxName);
    await viewBox.clear();
    for (final entry in viewPrefs.entries) {
      final key = entry.key;
      final val = entry.value;
      if (val is String) {
        await viewBox.put(key, val);
      }
    }

    final filterBox = Hive.box(filterPreferencesBoxName);
    await filterBox.clear();
    for (final entry in filterPrefs.entries) {
      await filterBox.put(entry.key, entry.value);
    }

    final sortBox = Hive.box(sortPreferencesBoxName);
    await sortBox.clear();
    for (final entry in sortPrefs.entries) {
      await sortBox.put(entry.key, entry.value);
    }

    final themeBox2 = Hive.box(themePreferencesBoxName);
    await themeBox2.clear();
    if (themePrefs.isNotEmpty) {
      if (themePrefs['theme_key'] != null) await themeBox2.put('theme_key', themePrefs['theme_key']);
      if (themePrefs['font_key'] != null) await themeBox2.put('font_key', themePrefs['font_key']);
      if (themePrefs['is_dark'] != null) await themeBox2.put('is_dark', themePrefs['is_dark']);
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore complete')));
  } catch (e, st) {
    debugPrint('Restore failed: $e\n$st');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore failed')));
  }
}

// Android save-as compatibility helper reusing the same platform channel name used in other export files
const MethodChannel _androidSaveChannel = MethodChannel('app.channel.savefile');

Future<String?> _androidSaveFileCompat(Uint8List bytes, String fileName) async {
  // Only meaningful on Android; callers already guard by trying desktop save first.
  if (!defaultTargetPlatform.toString().contains('android')) return null;
  try {
    final result = await _androidSaveChannel.invokeMethod<Object?>('saveFile', <String, dynamic>{
      'fileName': fileName,
      'bytes': bytes,
    });
    if (result is String) return result;
    return null;
  } on PlatformException catch (e) {
    debugPrint('androidSaveFile PlatformException: ${e.message}');
    return null;
  } catch (e) {
    debugPrint('androidSaveFile error: $e');
    return null;
  }
}


