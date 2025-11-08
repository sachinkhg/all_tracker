import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants.dart';
import '../models/backup_manifest.dart';
import '../../../../data/models/goal_model.dart';
import '../../../../data/models/milestone_model.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/habit_model.dart';
import '../../../../data/models/habit_completion_model.dart';

/// Service for building backup snapshots from Hive data.
class BackupBuilderService {
  static const String _currentVersion = '1';
  static const int _currentDbSchemaVersion = 7;

  /// Create a JSON snapshot of all Hive boxes.
  Future<Map<String, dynamic>> createBackupSnapshot() async {
    final snapshot = <String, dynamic>{
      'version': _currentVersion,
      'dbSchemaVersion': _currentDbSchemaVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    // Export Goals
    final goalsBox = Hive.box<GoalModel>(goalBoxName);
    snapshot['goals'] = goalsBox.values.map((g) => {
          'id': g.id,
          'name': g.name,
          'description': g.description,
          'targetDate': g.targetDate?.toUtc().toIso8601String(),
          'context': g.context,
          'isCompleted': g.isCompleted,
        }).toList();

    // Export Milestones
    final milestonesBox = Hive.box<MilestoneModel>(milestoneBoxName);
    snapshot['milestones'] = milestonesBox.values.map((m) => {
          'id': m.id,
          'name': m.name,
          'description': m.description,
          'plannedValue': m.plannedValue,
          'actualValue': m.actualValue,
          'targetDate': m.targetDate?.toUtc().toIso8601String(),
          'goalId': m.goalId,
        }).toList();

    // Export Tasks
    final tasksBox = Hive.box<TaskModel>(taskBoxName);
    snapshot['tasks'] = tasksBox.values.map((t) => {
          'id': t.id,
          'name': t.name,
          'targetDate': t.targetDate?.toUtc().toIso8601String(),
          'milestoneId': t.milestoneId,
          'goalId': t.goalId,
          'status': t.status,
        }).toList();

    // Export Habits
    final habitsBox = Hive.box<HabitModel>(habitBoxName);
    snapshot['habits'] = habitsBox.values.map((h) => {
          'id': h.id,
          'name': h.name,
          'description': h.description,
          'milestoneId': h.milestoneId,
          'goalId': h.goalId,
          'rrule': h.rrule,
          'targetCompletions': h.targetCompletions,
          'isActive': h.isActive,
        }).toList();

    // Export Habit Completions
    final completionsBox = Hive.box<HabitCompletionModel>(habitCompletionBoxName);
    snapshot['habit_completions'] = completionsBox.values.map((c) => {
          'id': c.id,
          'habitId': c.habitId,
          'completionDate': c.completionDate.toUtc().toIso8601String(),
          'note': c.note,
        }).toList();

    // Export Preferences
    final viewPrefsBox = Hive.box(viewPreferencesBoxName);
    snapshot['view_preferences'] = _exportPreferences(viewPrefsBox);

    final filterPrefsBox = Hive.box(filterPreferencesBoxName);
    snapshot['filter_preferences'] = _exportPreferences(filterPrefsBox);

    final sortPrefsBox = Hive.box(sortPreferencesBoxName);
    snapshot['sort_preferences'] = _exportPreferences(sortPrefsBox);

    final themeBox = Hive.box(themePreferencesBoxName);
    snapshot['theme_preferences'] = {
      'theme_key': themeBox.get('theme_key'),
      'font_key': themeBox.get('font_key'),
      'is_dark': themeBox.get('is_dark'),
    };

    return snapshot;
  }

  Map<String, dynamic> _exportPreferences(Box box) {
    final prefs = <String, dynamic>{};
    for (final key in box.keys) {
      prefs[key.toString()] = box.get(key);
    }
    return prefs;
  }

  /// Compress snapshot data using gzip.
  /// 
  /// Returns the compressed data as bytes.
  Future<Uint8List> compressSnapshot(Map<String, dynamic> snapshot) async {
    final jsonString = jsonEncode(snapshot);
    final input = utf8.encode(jsonString);

    // Note: In production, use dart:io's gzip.encode or package:archive
    // For now, return uncompressed (add compression later if needed)
    return Uint8List.fromList(input);
  }

  /// Calculate SHA-256 checksum of data.
  /// 
  /// Returns the checksum as a hexadecimal string.
  Future<String> calculateChecksum(Uint8List data) async {
    final hash = await Sha256().hash(data);
    return hash.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Build a backup manifest with file checksums.
  Future<BackupManifest> buildManifest({
    required String deviceId,
    required List<Uint8List> dataChunks,
    required Uint8List iv,
    String? kdfSalt,
    int? kdfIterations,
    required bool isE2EE,
  }) async {
    final files = <BackupFile>[];

    // Calculate checksum for each data chunk
    for (int i = 0; i < dataChunks.length; i++) {
      final checksum = await calculateChecksum(dataChunks[i]);
      files.add(BackupFile(
        path: i == 0 ? 'backup_data.json.gz' : 'backup_chunk_$i.gz',
        sha256: checksum,
      ));
    }

    return BackupManifest(
      version: _currentVersion,
      createdAt: DateTime.now(),
      appVersion: '1.0.0', // TODO: Get from package_info
      dbSchemaVersion: _currentDbSchemaVersion,
      deviceId: deviceId,
      files: files,
      kdf: (isE2EE && kdfSalt != null && kdfIterations != null)
          ? KdfConfig(
              alg: 'PBKDF2',
              salt: kdfSalt,
              iterations: kdfIterations,
            )
          : null,
      encryption: EncryptionConfig(
        alg: 'AES-256-GCM',
        iv: base64Encode(iv),
      ),
    );
  }
}

