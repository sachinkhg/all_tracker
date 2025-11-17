import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/constants.dart';
import '../../core/encryption_service.dart';
import '../../core/device_info_service.dart';
import '../datasources/google_auth_datasource.dart';
import '../datasources/drive_api_client.dart';
import '../datasources/backup_metadata_local_datasource.dart';
import '../services/backup_builder_service.dart';
import '../models/backup_manifest.dart';
import '../models/backup_metadata_model.dart';
import '../../domain/entities/backup_metadata.dart';
import '../../domain/entities/backup_result.dart';
import '../../domain/entities/restore_result.dart';
import '../../domain/entities/backup_progress.dart';
import '../../domain/entities/backup_mode.dart';
import '../../domain/repositories/backup_repository.dart';
import '../../../../data/models/goal_model.dart';
import '../../../../data/models/milestone_model.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/habit_model.dart';
import '../../../../data/models/habit_completion_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Implementation of BackupRepository.
class BackupRepositoryImpl implements BackupRepository {
  final GoogleAuthDataSource _googleAuth;
  final DriveApiClient _driveApi;
  final EncryptionService _encryptionService;
  final BackupBuilderService _backupBuilder;
  final BackupMetadataLocalDataSource _metadataDataSource;
  final DeviceInfoService _deviceInfoService;

  final StreamController<BackupProgress> _progressController =
      StreamController<BackupProgress>.broadcast();

  BackupRepositoryImpl({
    required GoogleAuthDataSource googleAuth,
    required DriveApiClient driveApi,
    required EncryptionService encryptionService,
    required BackupBuilderService backupBuilder,
    required BackupMetadataLocalDataSource metadataDataSource,
    required DeviceInfoService deviceInfoService,
  })  : _googleAuth = googleAuth,
        _driveApi = driveApi,
        _encryptionService = encryptionService,
        _backupBuilder = backupBuilder,
        _metadataDataSource = metadataDataSource,
        _deviceInfoService = deviceInfoService;

  @override
  Stream<BackupProgress> get backupProgress => _progressController.stream;

  @override
  Future<BackupResult> createBackup({
    required BackupMode mode,
    String? passphrase,
  }) async {
    try {
      _emitProgress('Exporting data', 0.1);

      // Build snapshot
      final snapshot = await _backupBuilder.createBackupSnapshot();
      _emitProgress('Compressing data', 0.3);

      // Compress
      final compressedData = await _backupBuilder.compressSnapshot(snapshot);

      // Encrypt
      _emitProgress('Encrypting backup', 0.5);
      Uint8List key;
      String? kdfSalt;
      int? kdfIterations;

      if (mode == BackupMode.e2ee && passphrase != null) {
        kdfSalt = base64Encode(await _encryptionService.generateSalt());
        kdfIterations = 200000;
        final saltBytes = base64Decode(kdfSalt);
        key = await _encryptionService.deriveKeyFromPassphrase(
          passphrase,
          saltBytes,
        );
      } else {
        key = await _encryptionService.generateDeviceKey();
      }

      final encryptionResult = await _encryptionService.encryptData(compressedData, key);

      // Build manifest
      final deviceId = await _deviceInfoService.getDeviceId();
      final manifest = await _backupBuilder.buildManifest(
        deviceId: deviceId,
        dataChunks: [Uint8List.fromList(utf8.encode(jsonEncode(encryptionResult)))],
        iv: base64Decode(encryptionResult['iv']!),
        kdfSalt: kdfSalt,
        kdfIterations: kdfIterations,
        isE2EE: mode == BackupMode.e2ee,
      );

      // Combine manifest + encrypted data
      final backupData = {
        'manifest': manifest.toJson(),
        'ciphertext': encryptionResult['ciphertext'],
        'mac': encryptionResult['mac'],
      };

      final backupBytes = Uint8List.fromList(utf8.encode(jsonEncode(backupData)));
      final fileName = 'goaltracker-backup-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}-${deviceId}.enc';

      _emitProgress('Uploading to Google Drive', 0.8);

      // Upload to Drive
      final appProperties = {
        'deviceId': deviceId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'isE2EE': (mode == BackupMode.e2ee).toString(),
        'schemaVersion': '7',
      };

      final fileId = await _driveApi.uploadFile(fileName, backupBytes, appProperties);

      // Save metadata locally
      final deviceDescription = await _deviceInfoService.getDeviceDescription();
      final metadata = BackupMetadataModel(
        id: fileId,
        fileName: fileName,
        createdAt: DateTime.now(),
        deviceId: deviceId,
        sizeBytes: backupBytes.length,
        isE2EE: mode == BackupMode.e2ee,
        deviceDescription: deviceDescription,
      );

      await _metadataDataSource.create(metadata);

      _emitProgress('Completed', 1.0);

      return BackupSuccess(backupId: fileId, sizeBytes: backupBytes.length);
    } catch (e) {
      return BackupFailure(error: e.toString());
    }
  }

  @override
  Future<List<BackupMetadata>> listBackups() async {
    try {
      final driveFiles = await _driveApi.listBackups();
      final localMetadata = await _metadataDataSource.getAll();

      // Merge and convert to domain entities
      final backups = <BackupMetadata>[];
      for (final file in driveFiles) {
        final localMeta = localMetadata.firstWhere(
          (m) => m.id == file['id'],
          orElse: () => _createMetadataFromDriveFile(file),
        );

        backups.add(BackupMetadata(
          id: localMeta.id,
          fileName: localMeta.fileName,
          createdAt: localMeta.createdAt,
          deviceId: localMeta.deviceId,
          deviceDescription: localMeta.deviceDescription,
          sizeBytes: localMeta.sizeBytes,
          isE2EE: localMeta.isE2EE,
        ));
      }

      // Sort by creation date (newest first)
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return backups;
    } catch (e) {
      throw Exception('Failed to list backups: $e');
    }
  }

  BackupMetadataModel _createMetadataFromDriveFile(Map<String, dynamic> file) {
    return BackupMetadataModel(
      id: file['id'] as String,
      fileName: file['name'] as String? ?? 'unknown',
      createdAt: _parseDriveDate(file['createdTime'] as String?),
      deviceId: file['appProperties']?['deviceId'] as String? ?? 'unknown',
      sizeBytes: int.tryParse(file['size'] as String? ?? '0') ?? 0,
      isE2EE: file['appProperties']?['isE2EE'] == 'true',
      deviceDescription: null,
    );
  }

  DateTime _parseDriveDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Future<RestoreResult> restoreBackup({
    required String backupId,
    String? passphrase,
  }) async {
    try {
      _emitProgress('Downloading backup', 0.2);

      // Download from Drive - if this fails, don't clear boxes
      final backupBytes = await _driveApi.downloadFile(backupId);
      final backupJson = jsonDecode(utf8.decode(backupBytes)) as Map<String, dynamic>;

      _emitProgress('Decrypting backup', 0.4);

      // Determine encryption mode from the backup manifest
      // If kdf is present in manifest, it's E2EE; otherwise it's device key mode
      final manifest = BackupManifest.fromJson(backupJson['manifest'] as Map<String, dynamic>);
      final isE2EE = manifest.kdf != null;

      // Decrypt - if this fails, don't clear boxes
      final key = isE2EE && passphrase != null
          ? await _derivePassphraseKey(backupJson, passphrase)
          : await _encryptionService.generateDeviceKey();

      final encryptionResult = {
        'iv': backupJson['manifest']['encryption']['iv'] as String,
        'ciphertext': backupJson['ciphertext'] as String,
        'mac': backupJson['mac'] as String,
      };

      final decryptedData = await _encryptionService.decryptData(encryptionResult, key);

      _emitProgress('Parsing backup data', 0.6);

      // Parse snapshot - if this fails, don't clear boxes
      final snapshot = jsonDecode(utf8.decode(decryptedData)) as Map<String, dynamic>;

      // Validate snapshot structure before clearing boxes
      if (!snapshot.containsKey('goals') || 
          !snapshot.containsKey('milestones') || 
          !snapshot.containsKey('tasks') ||
          !snapshot.containsKey('habits') ||
          !snapshot.containsKey('habit_completions')) {
        throw Exception('Invalid backup format: missing required data sections');
      }

      _emitProgress('Restoring data', 0.7);

      // Only clear boxes AFTER successful download, decrypt, and validation
      // This ensures we don't lose data if restore fails
      await _clearAllBoxes();

      // Import data - if this fails, data is already cleared but at least we tried
      await _importData(snapshot);

      _emitProgress('Completed', 1.0);

      return RestoreSuccess();
    } on Exception catch (e) {
      // Check if this is an authentication error
      final errorMessage = e.toString();
      if (errorMessage.contains('Not authenticated') || 
          errorMessage.contains('401') ||
          errorMessage.contains('unauthorized')) {
        // Auth error - don't clear boxes, preserve existing data
        return RestoreFailure(
          error: 'Authentication failed. Please sign in again and try restoring the backup.',
        );
      }
      // Return failure without clearing boxes if error occurs before clearing
      // This preserves existing data if restore fails early
      return RestoreFailure(error: errorMessage);
    } catch (e) {
      // Catch any other errors
      return RestoreFailure(error: 'Restore failed: ${e.toString()}');
    }
  }

  Future<Uint8List> _derivePassphraseKey(Map<String, dynamic> backupJson, String passphrase) async {
    final manifest = BackupManifest.fromJson(backupJson['manifest'] as Map<String, dynamic>);
    if (manifest.kdf == null) {
      throw Exception('Backup is E2EE but no KDF config found');
    }

    final salt = base64Decode(manifest.kdf!.salt);
    return await _encryptionService.deriveKeyFromPassphrase(passphrase, salt);
  }

  Future<void> _clearAllBoxes() async {
    // Use typed boxes - they should already be open from initialization
    // Hive.box<T>() returns the already-opened box, it doesn't try to open it again
    final goalBox = Hive.box<GoalModel>(goalBoxName);
    final milestoneBox = Hive.box<MilestoneModel>(milestoneBoxName);
    final taskBox = Hive.box<TaskModel>(taskBoxName);
    final habitBox = Hive.box<HabitModel>(habitBoxName);
    final completionBox = Hive.box<HabitCompletionModel>(habitCompletionBoxName);
    
    await goalBox.clear();
    await milestoneBox.clear();
    await taskBox.clear();
    await habitBox.clear();
    await completionBox.clear();
  }

  Future<void> _importData(Map<String, dynamic> snapshot) async {
    // Import Goals
    final goals = snapshot['goals'] as List<dynamic>? ?? [];
    final goalBox = Hive.box<GoalModel>(goalBoxName);
    for (final g in goals) {
      final m = g as Map<String, dynamic>;
      final model = GoalModel(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        targetDate: (m['targetDate'] != null) ? DateTime.tryParse(m['targetDate'] as String) : null,
        context: m['context'] as String?,
        isCompleted: (m['isCompleted'] as bool?) ?? false,
      );
      await goalBox.put(model.id, model);
    }

    // Import Milestones
    final milestones = snapshot['milestones'] as List<dynamic>? ?? [];
    final milestoneBox = Hive.box<MilestoneModel>(milestoneBoxName);
    for (final ms in milestones) {
      final m = ms as Map<String, dynamic>;
      final model = MilestoneModel(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        plannedValue: (m['plannedValue'] as num?)?.toDouble(),
        actualValue: (m['actualValue'] as num?)?.toDouble(),
        targetDate: (m['targetDate'] != null) ? DateTime.tryParse(m['targetDate'] as String) : null,
        goalId: m['goalId'] as String,
      );
      await milestoneBox.put(model.id, model);
    }

    // Import Tasks
    final tasks = snapshot['tasks'] as List<dynamic>? ?? [];
    final taskBox = Hive.box<TaskModel>(taskBoxName);
    for (final t in tasks) {
      final m = t as Map<String, dynamic>;
      final model = TaskModel(
        id: m['id'] as String,
        name: m['name'] as String,
        targetDate: (m['targetDate'] != null) ? DateTime.tryParse(m['targetDate'] as String) : null,
        milestoneId: m['milestoneId'] as String,
        goalId: m['goalId'] as String,
        status: (m['status'] as String?) ?? 'To Do',
      );
      await taskBox.put(model.id, model);
    }

    // Import Habits
    final habits = snapshot['habits'] as List<dynamic>? ?? [];
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

    // Import Habit Completions
    final completions = snapshot['habit_completions'] as List<dynamic>? ?? [];
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

    // Import Preferences (optional - don't fail if missing)
    final viewPrefs = snapshot['view_preferences'] as Map<String, dynamic>? ?? {};
    final viewBox = Hive.box(viewPreferencesBoxName);
    await viewBox.clear();
    for (final entry in viewPrefs.entries) {
      final key = entry.key;
      final val = entry.value;
      if (val is String) {
        await viewBox.put(key, val);
      }
    }

    final filterPrefs = snapshot['filter_preferences'] as Map<String, dynamic>? ?? {};
    final filterBox = Hive.box(filterPreferencesBoxName);
    await filterBox.clear();
    for (final entry in filterPrefs.entries) {
      await filterBox.put(entry.key, entry.value);
    }

    final sortPrefs = snapshot['sort_preferences'] as Map<String, dynamic>? ?? {};
    final sortBox = Hive.box(sortPreferencesBoxName);
    await sortBox.clear();
    for (final entry in sortPrefs.entries) {
      await sortBox.put(entry.key, entry.value);
    }

    final themePrefs = snapshot['theme_preferences'] as Map<String, dynamic>? ?? {};
    final themeBox = Hive.box(themePreferencesBoxName);
    await themeBox.clear();
    if (themePrefs.isNotEmpty) {
      if (themePrefs['theme_key'] != null) await themeBox.put('theme_key', themePrefs['theme_key']);
      if (themePrefs['font_key'] != null) await themeBox.put('font_key', themePrefs['font_key']);
      if (themePrefs['is_dark'] != null) await themeBox.put('is_dark', themePrefs['is_dark']);
    }
  }

  @override
  Future<void> deleteBackup(String backupId) async {
    try {
      await _driveApi.deleteFile(backupId);
      await _metadataDataSource.delete(backupId);
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }

  void _emitProgress(String stage, double progress) {
    _progressController.add(BackupProgress(stage: stage, progress: progress));
  }
}

