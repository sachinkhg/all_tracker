import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../../../trackers/goal_tracker/core/constants.dart' as goal_constants;
import '../../../../trackers/travel_tracker/core/constants.dart' as travel_constants;
import '../../../../trackers/password_tracker/core/constants.dart' as password_constants;
import '../../../../trackers/expense_tracker/core/constants.dart' as expense_tracker_constants;
import '../../../../utilities/investment_planner/core/constants.dart' as investment_constants;
import '../../../../utilities/retirement_planner/core/constants.dart' as retirement_constants;
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
import '../../../../trackers/goal_tracker/data/models/goal_model.dart';
import '../../../../trackers/goal_tracker/data/models/milestone_model.dart';
import '../../../../trackers/goal_tracker/data/models/task_model.dart';
import '../../../../trackers/goal_tracker/data/models/habit_model.dart';
import '../../../../trackers/goal_tracker/data/models/habit_completion_model.dart';
import '../../../../trackers/travel_tracker/data/models/trip_model.dart';
import '../../../../trackers/travel_tracker/data/models/trip_profile_model.dart';
import '../../../../trackers/travel_tracker/data/models/traveler_model.dart';
import '../../../../trackers/travel_tracker/data/models/itinerary_day_model.dart';
import '../../../../trackers/travel_tracker/data/models/itinerary_item_model.dart';
import '../../../../trackers/travel_tracker/data/models/journal_entry_model.dart';
import '../../../../trackers/travel_tracker/data/models/photo_model.dart';
import '../../../../trackers/travel_tracker/data/models/expense_model.dart' as travel_expense;
import '../../../../trackers/expense_tracker/data/models/expense_model.dart' as expense_tracker_expense;
import '../../../../trackers/password_tracker/data/models/password_model.dart';
import '../../../../trackers/password_tracker/data/models/secret_question_model.dart';
import '../../../../utilities/investment_planner/data/models/investment_component_model.dart';
import '../../../../utilities/investment_planner/data/models/income_category_model.dart';
import '../../../../utilities/investment_planner/data/models/expense_category_model.dart';
import '../../../../utilities/investment_planner/data/models/investment_plan_model.dart';
import '../../../../utilities/investment_planner/data/models/income_entry_model.dart';
import '../../../../utilities/investment_planner/data/models/expense_entry_model.dart';
import '../../../../utilities/investment_planner/data/models/component_allocation_model.dart';
import '../../../../utilities/retirement_planner/data/models/retirement_plan_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Implementation of BackupRepository.
class BackupRepositoryImpl implements BackupRepository {
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
  })  : _driveApi = driveApi,
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
    String? name,
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
      final fileName = 'alltracker-backup-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}-$deviceId.enc';

      _emitProgress('Uploading to Google Drive', 0.8);

      // Upload to Drive
      final appProperties = {
        'deviceId': deviceId,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'isE2EE': (mode == BackupMode.e2ee).toString(),
        'schemaVersion': '9',
        if (name != null && name.isNotEmpty) 'backupName': name,
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
        name: name,
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
          name: localMeta.name,
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
      id: _safeString(file, 'id', ''),
      fileName: _safeStringNullable(file, 'name') ?? 'unknown',
      createdAt: _parseDriveDate(_safeStringNullable(file, 'createdTime')),
      deviceId: (file['appProperties'] as Map<String, dynamic>?)?['deviceId'] as String? ?? 'unknown',
      sizeBytes: int.tryParse(_safeStringNullable(file, 'size') ?? '0') ?? 0,
      isE2EE: (file['appProperties'] as Map<String, dynamic>?)?['isE2EE'] == 'true',
      deviceDescription: null,
      name: (file['appProperties'] as Map<String, dynamic>?)?['backupName'] as String?,
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

      final manifestMap = backupJson['manifest'] as Map<String, dynamic>?;
      final encryptionMap = manifestMap?['encryption'] as Map<String, dynamic>?;
      
      // Validate required encryption fields
      final iv = encryptionMap != null ? _safeStringNullable(encryptionMap, 'iv') : null;
      final ciphertext = _safeStringNullable(backupJson, 'ciphertext');
      final mac = _safeStringNullable(backupJson, 'mac');
      
      if (iv == null || iv.isEmpty || ciphertext == null || ciphertext.isEmpty || mac == null || mac.isEmpty) {
        throw Exception('Invalid backup format: missing encryption data');
      }
      
      final encryptionResult = {
        'iv': iv,
        'ciphertext': ciphertext,
        'mac': mac,
      };

      final decryptedData = await _encryptionService.decryptData(encryptionResult, key);

      _emitProgress('Parsing backup data', 0.6);

      // Parse snapshot - if this fails, don't clear boxes
      final snapshot = jsonDecode(utf8.decode(decryptedData)) as Map<String, dynamic>;
      
      print('[RESTORE] Snapshot parsed successfully');
      print('[RESTORE] Snapshot version: ${snapshot['version']}');
      print('[RESTORE] Snapshot dbSchemaVersion: ${snapshot['dbSchemaVersion']}');
      print('[RESTORE] Snapshot createdAt: ${snapshot['createdAt']}');
      print('[RESTORE] Snapshot contains keys: ${snapshot.keys.toList()}');
      print('[RESTORE] Snapshot has passwords: ${snapshot.containsKey('passwords')}');
      print('[RESTORE] Snapshot has secret_questions: ${snapshot.containsKey('secret_questions')}');
      print('[RESTORE] Snapshot has expense_tracker_expenses: ${snapshot.containsKey('expense_tracker_expenses')}');
      
      if (snapshot.containsKey('passwords')) {
        final passwords = snapshot['passwords'] as List<dynamic>?;
        print('[RESTORE] Passwords array length in snapshot: ${passwords?.length ?? 0}');
        if (passwords != null && passwords.isNotEmpty) {
          print('[RESTORE] First password sample: ${passwords.first}');
        }
      }
      
      if (snapshot.containsKey('secret_questions')) {
        final secretQuestions = snapshot['secret_questions'] as List<dynamic>?;
        print('[RESTORE] Secret questions array length in snapshot: ${secretQuestions?.length ?? 0}');
      }

      // Validate snapshot structure before clearing boxes
      // At minimum, should have goals (for backward compatibility with old backups)
      if (!snapshot.containsKey('goals')) {
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
    
    // Goal Tracker boxes
    await Hive.box<GoalModel>(goal_constants.goalBoxName).clear();
    await Hive.box<MilestoneModel>(goal_constants.milestoneBoxName).clear();
    await Hive.box<TaskModel>(goal_constants.taskBoxName).clear();
    await Hive.box<HabitModel>(goal_constants.habitBoxName).clear();
    await Hive.box<HabitCompletionModel>(goal_constants.habitCompletionBoxName).clear();
    
    // Travel Tracker boxes
    await Hive.box<TripModel>(travel_constants.tripBoxName).clear();
    await Hive.box<TripProfileModel>(travel_constants.tripProfileBoxName).clear();
    await Hive.box<TravelerModel>(travel_constants.travelerBoxName).clear();
    await Hive.box<ItineraryDayModel>(travel_constants.itineraryDayBoxName).clear();
    await Hive.box<ItineraryItemModel>(travel_constants.itineraryItemBoxName).clear();
    await Hive.box<JournalEntryModel>(travel_constants.journalEntryBoxName).clear();
    await Hive.box<PhotoModel>(travel_constants.photoBoxName).clear();
    await Hive.box<travel_expense.ExpenseModel>(travel_constants.expenseBoxName).clear();
    
    // Expense Tracker boxes
    await Hive.box<expense_tracker_expense.ExpenseModel>(expense_tracker_constants.expenseTrackerBoxName).clear();
    
    // Investment Planner boxes
    await Hive.box<InvestmentComponentModel>(investment_constants.investmentComponentBoxName).clear();
    await Hive.box<IncomeCategoryModel>(investment_constants.incomeCategoryBoxName).clear();
    await Hive.box<ExpenseCategoryModel>(investment_constants.expenseCategoryBoxName).clear();
    await Hive.box<InvestmentPlanModel>(investment_constants.investmentPlanBoxName).clear();
    
    // Retirement Planner boxes
    await Hive.box<RetirementPlanModel>(retirement_constants.retirementPlanBoxName).clear();
    await Hive.box(retirement_constants.retirementPreferencesBoxName).clear();
    
    // Password Tracker boxes
    print('[RESTORE] Clearing Password Tracker boxes...');
    final passwordBox = Hive.box<PasswordModel>(password_constants.passwordBoxName);
    final secretQuestionBox = Hive.box<SecretQuestionModel>(password_constants.secretQuestionBoxName);
    print('[RESTORE] Password box length before clear: ${passwordBox.length}');
    print('[RESTORE] Secret question box length before clear: ${secretQuestionBox.length}');
    await passwordBox.clear();
    await secretQuestionBox.clear();
    print('[RESTORE] Password box length after clear: ${passwordBox.length}');
    print('[RESTORE] Secret question box length after clear: ${secretQuestionBox.length}');
    
    // App-wide preferences (will be restored if present in backup)
    await Hive.box(goal_constants.viewPreferencesBoxName).clear();
    await Hive.box(goal_constants.filterPreferencesBoxName).clear();
    await Hive.box(goal_constants.sortPreferencesBoxName).clear();
    await Hive.box(goal_constants.themePreferencesBoxName).clear();
  }

  /// Deserializes a date-only field from ISO string to local DateTime.
  /// 
  /// This parses the UTC date string, extracts the date components (year, month, day),
  /// and creates a local DateTime at midnight to preserve the date correctly
  /// in the user's timezone.
  static DateTime? _deserializeDateOnly(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final parsed = DateTime.parse(dateStr);
      // Extract date components and create local date at midnight
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  /// Deserializes a required date-only field from ISO string to local DateTime.
  static DateTime _deserializeDateOnlyRequired(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      // Extract date components and create local date at midnight
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Safely extracts a String from a map, providing a default if null.
  /// Use this for required String fields that might be null in older backups.
  static String _safeString(Map<String, dynamic> map, String key, String defaultValue) {
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  /// Safely extracts a nullable String from a map.
  static String? _safeStringNullable(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  Future<void> _importData(Map<String, dynamic> snapshot) async {
    // ========================================================================
    // Goal Tracker Data
    // ========================================================================
    final goals = snapshot['goals'] as List<dynamic>? ?? [];
    final goalBox = Hive.box<GoalModel>(goal_constants.goalBoxName);
    for (final g in goals) {
      final m = g as Map<String, dynamic>;
      final model = GoalModel(
        id: _safeString(m, 'id', ''),
        name: _safeString(m, 'name', 'Unnamed Goal'),
        description: _safeStringNullable(m, 'description'),
        targetDate: (m['targetDate'] != null) ? DateTime.tryParse(_safeString(m, 'targetDate', '')) : null,
        context: _safeStringNullable(m, 'context'),
        isCompleted: (m['isCompleted'] as bool?) ?? false,
      );
      if (model.id.isEmpty) continue; // Skip invalid entries
      await goalBox.put(model.id, model);
    }

    final milestones = snapshot['milestones'] as List<dynamic>? ?? [];
    final milestoneBox = Hive.box<MilestoneModel>(goal_constants.milestoneBoxName);
    for (final ms in milestones) {
      final m = ms as Map<String, dynamic>;
      final model = MilestoneModel(
        id: _safeString(m, 'id', ''),
        name: _safeString(m, 'name', 'Unnamed Milestone'),
        description: _safeStringNullable(m, 'description'),
        plannedValue: (m['plannedValue'] as num?)?.toDouble(),
        actualValue: (m['actualValue'] as num?)?.toDouble(),
        targetDate: (m['targetDate'] != null) ? DateTime.tryParse(_safeString(m, 'targetDate', '')) : null,
        goalId: _safeString(m, 'goalId', ''),
      );
      if (model.id.isEmpty) continue; // Skip invalid entries
      await milestoneBox.put(model.id, model);
    }

    final tasks = snapshot['tasks'] as List<dynamic>? ?? [];
    final taskBox = Hive.box<TaskModel>(goal_constants.taskBoxName);
    for (final t in tasks) {
      final m = t as Map<String, dynamic>;
      final model = TaskModel(
        id: _safeString(m, 'id', ''),
        name: _safeString(m, 'name', 'Unnamed Task'),
        targetDate: (m['targetDate'] != null) ? DateTime.tryParse(_safeString(m, 'targetDate', '')) : null,
        milestoneId: _safeString(m, 'milestoneId', ''),
        goalId: _safeString(m, 'goalId', ''),
        status: _safeString(m, 'status', 'To Do'),
      );
      if (model.id.isEmpty) continue; // Skip invalid entries
      await taskBox.put(model.id, model);
    }

    final habits = snapshot['habits'] as List<dynamic>? ?? [];
    final habitBox = Hive.box<HabitModel>(goal_constants.habitBoxName);
    for (final h in habits) {
      final m = h as Map<String, dynamic>;
      final model = HabitModel(
        id: _safeString(m, 'id', ''),
        name: _safeString(m, 'name', 'Unnamed Habit'),
        description: _safeStringNullable(m, 'description'),
        milestoneId: _safeString(m, 'milestoneId', ''),
        goalId: _safeString(m, 'goalId', ''),
        rrule: _safeString(m, 'rrule', 'FREQ=DAILY'), // Default to daily if missing
        targetCompletions: (m['targetCompletions'] as num?)?.toInt(),
        isActive: (m['isActive'] as bool?) ?? true,
      );
      if (model.id.isEmpty) continue; // Skip invalid entries
      await habitBox.put(model.id, model);
    }

    final completions = snapshot['habit_completions'] as List<dynamic>? ?? [];
    final completionBox = Hive.box<HabitCompletionModel>(goal_constants.habitCompletionBoxName);
    for (final c in completions) {
      final m = c as Map<String, dynamic>;
      final model = HabitCompletionModel(
        id: _safeString(m, 'id', ''),
        habitId: _safeString(m, 'habitId', ''),
        completionDate: DateTime.tryParse(_safeString(m, 'completionDate', '')) ?? DateTime.now(),
        note: _safeStringNullable(m, 'note'),
      );
      if (model.id.isEmpty) continue; // Skip invalid entries
      await completionBox.put(model.id, model);
    }

    // ========================================================================
    // Travel Tracker Data (optional - only restore if present in backup)
    // ========================================================================
    if (snapshot.containsKey('trips')) {
      final trips = snapshot['trips'] as List<dynamic>? ?? [];
      final tripBox = Hive.box<TripModel>(travel_constants.tripBoxName);
      for (final t in trips) {
        final m = t as Map<String, dynamic>;
        final model = TripModel(
          id: _safeString(m, 'id', ''),
          title: _safeString(m, 'title', 'Unnamed Trip'),
          destination: _safeStringNullable(m, 'destination'),
          startDate: _deserializeDateOnly(_safeStringNullable(m, 'startDate')),
          endDate: _deserializeDateOnly(_safeStringNullable(m, 'endDate')),
          description: _safeStringNullable(m, 'description'),
          tripTypeIndex: (m['tripTypeIndex'] as num?)?.toInt(),
          destinationLatitude: (m['destinationLatitude'] as num?)?.toDouble(),
          destinationLongitude: (m['destinationLongitude'] as num?)?.toDouble(),
          destinationMapLink: _safeStringNullable(m, 'destinationMapLink'),
          createdAt: DateTime.tryParse(_safeString(m, 'createdAt', '')) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(_safeString(m, 'updatedAt', '')) ?? DateTime.now(),
        );
        if (model.id.isEmpty) continue; // Skip invalid entries
        await tripBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('trip_profiles')) {
      final tripProfiles = snapshot['trip_profiles'] as List<dynamic>? ?? [];
      final tripProfileBox = Hive.box<TripProfileModel>(travel_constants.tripProfileBoxName);
      for (final tp in tripProfiles) {
        final m = tp as Map<String, dynamic>;
        final model = TripProfileModel(
          id: _safeString(m, 'id', ''),
          tripId: _safeString(m, 'tripId', ''),
          travelerName: _safeStringNullable(m, 'travelerName'),
          email: _safeStringNullable(m, 'email'),
          notes: _safeStringNullable(m, 'notes'),
          createdAt: DateTime.tryParse(_safeString(m, 'createdAt', '')) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(_safeString(m, 'updatedAt', '')) ?? DateTime.now(),
        );
        if (model.id.isEmpty) continue; // Skip invalid entries
        await tripProfileBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('travelers')) {
      final travelers = snapshot['travelers'] as List<dynamic>? ?? [];
      final travelerBox = Hive.box<TravelerModel>(travel_constants.travelerBoxName);
      for (final t in travelers) {
        final m = t as Map<String, dynamic>;
        final model = TravelerModel(
          id: _safeString(m, 'id', ''),
          tripId: _safeString(m, 'tripId', ''),
          name: _safeString(m, 'name', 'Unnamed Traveler'),
          relationship: _safeStringNullable(m, 'relationship'),
          email: _safeStringNullable(m, 'email'),
          phone: _safeStringNullable(m, 'phone'),
          notes: _safeStringNullable(m, 'notes'),
          isMainTraveler: (m['isMainTraveler'] as bool?) ?? false,
          createdAt: DateTime.tryParse(_safeString(m, 'createdAt', '')) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(_safeString(m, 'updatedAt', '')) ?? DateTime.now(),
        );
        if (model.id.isEmpty) continue; // Skip invalid entries
        await travelerBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('itinerary_days')) {
      final itineraryDays = snapshot['itinerary_days'] as List<dynamic>? ?? [];
      final itineraryDayBox = Hive.box<ItineraryDayModel>(travel_constants.itineraryDayBoxName);
      for (final id in itineraryDays) {
        final m = id as Map<String, dynamic>;
        final model = ItineraryDayModel(
          id: _safeString(m, 'id', ''),
          tripId: _safeString(m, 'tripId', ''),
          date: _deserializeDateOnlyRequired(_safeString(m, 'date', DateTime.now().toIso8601String())),
          createdAt: DateTime.tryParse(_safeString(m, 'createdAt', '')) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(_safeString(m, 'updatedAt', '')) ?? DateTime.now(),
        );
        if (model.id.isEmpty) continue; // Skip invalid entries
        await itineraryDayBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('itinerary_items')) {
      final itineraryItems = snapshot['itinerary_items'] as List<dynamic>? ?? [];
      final itineraryItemBox = Hive.box<ItineraryItemModel>(travel_constants.itineraryItemBoxName);
      for (final ii in itineraryItems) {
        final m = ii as Map<String, dynamic>;
        final model = ItineraryItemModel(
          id: _safeString(m, 'id', ''),
          dayId: _safeString(m, 'dayId', ''),
          typeIndex: (m['typeIndex'] as num?)?.toInt() ?? 0,
          title: _safeString(m, 'title', 'Untitled Item'),
          time: (m['time'] != null) ? DateTime.tryParse(_safeString(m, 'time', '')) : null,
          location: _safeStringNullable(m, 'location'),
          notes: _safeStringNullable(m, 'notes'),
          mapLink: _safeStringNullable(m, 'mapLink'),
          createdAt: DateTime.tryParse(_safeString(m, 'createdAt', '')) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(_safeString(m, 'updatedAt', '')) ?? DateTime.now(),
        );
        if (model.id.isEmpty) continue; // Skip invalid entries
        await itineraryItemBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('journal_entries')) {
      final journalEntries = snapshot['journal_entries'] as List<dynamic>? ?? [];
      final journalEntryBox = Hive.box<JournalEntryModel>(travel_constants.journalEntryBoxName);
      for (final je in journalEntries) {
        final m = je as Map<String, dynamic>;
        final model = JournalEntryModel(
          id: _safeString(m, 'id', ''),
          tripId: _safeString(m, 'tripId', ''),
          date: DateTime.tryParse(_safeString(m, 'date', '')) ?? DateTime.now(),
          content: _safeString(m, 'content', ''), // Empty string default for content
          createdAt: DateTime.tryParse(_safeString(m, 'createdAt', '')) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(_safeString(m, 'updatedAt', '')) ?? DateTime.now(),
        );
        if (model.id.isEmpty) continue; // Skip invalid entries
        await journalEntryBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('photos')) {
      final photos = snapshot['photos'] as List<dynamic>? ?? [];
      final photoBox = Hive.box<PhotoModel>(travel_constants.photoBoxName);
      for (final p in photos) {
        final m = p as Map<String, dynamic>;
        final model = PhotoModel(
          id: _safeString(m, 'id', ''),
          journalEntryId: _safeString(m, 'journalEntryId', ''),
          filePath: _safeString(m, 'filePath', ''), // Empty string default for filePath
          caption: _safeStringNullable(m, 'caption'),
          dateTaken: (m['dateTaken'] != null) ? DateTime.tryParse(_safeString(m, 'dateTaken', '')) : null,
          taggedDay: (m['taggedDay'] != null) ? DateTime.tryParse(_safeString(m, 'taggedDay', '')) : null,
          taggedLocation: _safeStringNullable(m, 'taggedLocation'),
          createdAt: DateTime.tryParse(_safeString(m, 'createdAt', '')) ?? DateTime.now(),
        );
        if (model.id.isEmpty) continue; // Skip invalid entries
        await photoBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('expenses')) {
      final expenses = snapshot['expenses'] as List<dynamic>? ?? [];
      final expenseBox = Hive.box<travel_expense.ExpenseModel>(travel_constants.expenseBoxName);
      for (final e in expenses) {
        final m = e as Map<String, dynamic>;
        final model = travel_expense.ExpenseModel(
          id: _safeString(m, 'id', ''),
          tripId: _safeString(m, 'tripId', ''),
          date: _deserializeDateOnlyRequired(_safeString(m, 'date', DateTime.now().toIso8601String())),
          categoryIndex: (m['categoryIndex'] as num?)?.toInt() ?? 0,
          amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
          currency: _safeString(m, 'currency', 'USD'), // Default to USD if missing
          description: _safeStringNullable(m, 'description'),
          paidBy: _safeStringNullable(m, 'paidBy'),
          createdAt: DateTime.tryParse(_safeString(m, 'createdAt', '')) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(_safeString(m, 'updatedAt', '')) ?? DateTime.now(),
        );
        if (model.id.isEmpty) continue; // Skip invalid entries
        await expenseBox.put(model.id, model);
      }
    }

    // ========================================================================
    // Investment Planner Data (optional - only restore if present in backup)
    // ========================================================================
    if (snapshot.containsKey('investment_components')) {
      final components = snapshot['investment_components'] as List<dynamic>? ?? [];
      final componentBox = Hive.box<InvestmentComponentModel>(investment_constants.investmentComponentBoxName);
      for (final ic in components) {
        final m = ic as Map<String, dynamic>;
        final model = InvestmentComponentModel(
          id: _safeString(m, 'id', ''),
          name: _safeString(m, 'name', 'Unnamed Component'),
          percentage: (m['percentage'] as num?)?.toDouble() ?? 0.0,
          minLimit: (m['minLimit'] as num?)?.toDouble(),
          maxLimit: (m['maxLimit'] as num?)?.toDouble(),
          priority: (m['priority'] as num?)?.toInt() ?? 0,
        );
        if (model.id.isEmpty) continue; // Skip invalid entries
        await componentBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('income_categories')) {
      final incomeCategories = snapshot['income_categories'] as List<dynamic>? ?? [];
      final incomeCategoryBox = Hive.box<IncomeCategoryModel>(investment_constants.incomeCategoryBoxName);
      for (final ic in incomeCategories) {
        final m = ic as Map<String, dynamic>;
        final model = IncomeCategoryModel(
          id: _safeString(m, 'id', ''),
          name: _safeString(m, 'name', 'Unnamed Category'),
        );
        if (model.id.isEmpty) continue; // Skip invalid entries
        await incomeCategoryBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('expense_categories')) {
      final expenseCategories = snapshot['expense_categories'] as List<dynamic>? ?? [];
      final expenseCategoryBox = Hive.box<ExpenseCategoryModel>(investment_constants.expenseCategoryBoxName);
      for (final ec in expenseCategories) {
        final m = ec as Map<String, dynamic>;
        final model = ExpenseCategoryModel(
          id: _safeString(m, 'id', ''),
          name: _safeString(m, 'name', 'Unnamed Category'),
        );
        if (model.id.isEmpty) continue; // Skip invalid entries
        await expenseCategoryBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('investment_plans')) {
      final investmentPlans = snapshot['investment_plans'] as List<dynamic>? ?? [];
      final investmentPlanBox = Hive.box<InvestmentPlanModel>(investment_constants.investmentPlanBoxName);
      for (final ip in investmentPlans) {
        final m = ip as Map<String, dynamic>;
        final incomeEntries = (m['incomeEntries'] as List<dynamic>? ?? []).map((ie) {
          final im = ie as Map<String, dynamic>;
          return IncomeEntryModel(
            id: _safeString(im, 'id', ''),
            categoryId: _safeString(im, 'categoryId', ''),
            amount: (im['amount'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
        final expenseEntries = (m['expenseEntries'] as List<dynamic>? ?? []).map((ee) {
          final em = ee as Map<String, dynamic>;
          return ExpenseEntryModel(
            id: _safeString(em, 'id', ''),
            categoryId: _safeString(em, 'categoryId', ''),
            amount: (em['amount'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
        final allocations = (m['allocations'] as List<dynamic>? ?? []).map((a) {
          final am = a as Map<String, dynamic>;
          return ComponentAllocationModel(
            componentId: _safeString(am, 'componentId', ''),
            allocatedAmount: (am['allocatedAmount'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
        final model = InvestmentPlanModel(
          id: _safeString(m, 'id', ''),
          name: _safeString(m, 'name', 'Unnamed Plan'),
          duration: _safeString(m, 'duration', 'Monthly'),
          period: _safeString(m, 'period', DateTime.now().toString()),
          incomeEntries: incomeEntries,
          expenseEntries: expenseEntries,
          allocations: allocations,
          createdAt: DateTime.tryParse(_safeString(m, 'createdAt', '')) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(_safeString(m, 'updatedAt', '')) ?? DateTime.now(),
        );
        await investmentPlanBox.put(model.id, model);
      }
    }

    // ========================================================================
    // Password Tracker Data (optional - only restore if present in backup)
    // ========================================================================
    print('[RESTORE] Checking for Password Tracker data in snapshot...');
    print('[RESTORE] Snapshot keys: ${snapshot.keys.toList()}');
    print('[RESTORE] Has passwords key: ${snapshot.containsKey('passwords')}');
    print('[RESTORE] Has secret_questions key: ${snapshot.containsKey('secret_questions')}');
    
    if (snapshot.containsKey('passwords')) {
      final passwords = snapshot['passwords'] as List<dynamic>? ?? [];
      print('[RESTORE] Found ${passwords.length} passwords in snapshot');
      final passwordBox = Hive.box<PasswordModel>(password_constants.passwordBoxName);
      print('[RESTORE] Password box length before restore: ${passwordBox.length}');
      
      int restoredCount = 0;
      int skippedCount = 0;
      
      for (final p in passwords) {
        try {
          final m = p as Map<String, dynamic>;
          print('[RESTORE] Processing password: id=${m['id']}, siteName=${m['siteName']}');
          
          final model = PasswordModel(
            id: _safeString(m, 'id', ''),
            siteName: _safeString(m, 'siteName', 'Unnamed Site'),
            url: _safeStringNullable(m, 'url'),
            username: _safeStringNullable(m, 'username'),
            encryptedPassword: _safeStringNullable(m, 'encryptedPassword'), // Restore encrypted as-is
            isGoogleSignIn: (m['isGoogleSignIn'] as bool?) ?? false,
            lastUpdated: DateTime.tryParse(_safeString(m, 'lastUpdated', '')) ?? DateTime.now(),
            is2FA: (m['is2FA'] as bool?) ?? false,
            categoryGroup: _safeStringNullable(m, 'categoryGroup'),
            hasSecretQuestions: (m['hasSecretQuestions'] as bool?) ?? false,
          );
          
          if (model.id.isEmpty) {
            print('[RESTORE] Skipping password with empty ID');
            skippedCount++;
            continue; // Skip invalid entries
          }
          
          await passwordBox.put(model.id, model);
          restoredCount++;
          print('[RESTORE] Restored password: id=${model.id}, siteName=${model.siteName}');
        } catch (e, stackTrace) {
          print('[RESTORE] Error restoring password: $e');
          print('[RESTORE] Stack trace: $stackTrace');
          skippedCount++;
        }
      }
      
      print('[RESTORE] Password restore completed: restored=$restoredCount, skipped=$skippedCount');
      print('[RESTORE] Password box length after restore: ${passwordBox.length}');
    } else {
      print('[RESTORE] WARNING: No passwords key found in snapshot!');
    }

    if (snapshot.containsKey('secret_questions')) {
      final secretQuestions = snapshot['secret_questions'] as List<dynamic>? ?? [];
      print('[RESTORE] Found ${secretQuestions.length} secret questions in snapshot');
      final secretQuestionBox = Hive.box<SecretQuestionModel>(password_constants.secretQuestionBoxName);
      print('[RESTORE] Secret question box length before restore: ${secretQuestionBox.length}');
      
      int restoredCount = 0;
      int skippedCount = 0;
      
      for (final sq in secretQuestions) {
        try {
          final m = sq as Map<String, dynamic>;
          print('[RESTORE] Processing secret question: id=${m['id']}, passwordId=${m['passwordId']}');
          
          final model = SecretQuestionModel(
            id: _safeString(m, 'id', ''),
            passwordId: _safeString(m, 'passwordId', ''),
            question: _safeString(m, 'question', ''), // Empty string default for question
            encryptedAnswer: _safeString(m, 'encryptedAnswer', ''), // Empty string default for encryptedAnswer
          );
          
          if (model.id.isEmpty) {
            print('[RESTORE] Skipping secret question with empty ID');
            skippedCount++;
            continue; // Skip invalid entries
          }
          
          await secretQuestionBox.put(model.id, model);
          restoredCount++;
          print('[RESTORE] Restored secret question: id=${model.id}, passwordId=${model.passwordId}');
        } catch (e, stackTrace) {
          print('[RESTORE] Error restoring secret question: $e');
          print('[RESTORE] Stack trace: $stackTrace');
          skippedCount++;
        }
      }
      
      print('[RESTORE] Secret question restore completed: restored=$restoredCount, skipped=$skippedCount');
      print('[RESTORE] Secret question box length after restore: ${secretQuestionBox.length}');
    } else {
      print('[RESTORE] WARNING: No secret_questions key found in snapshot!');
    }
    
    print('[RESTORE] Password Tracker restore process completed');

    // ========================================================================
    // Expense Tracker Data (optional - only restore if present in backup)
    // ========================================================================
    print('[RESTORE] Checking for Expense Tracker data in snapshot...');
    print('[RESTORE] Has expense_tracker_expenses key: ${snapshot.containsKey('expense_tracker_expenses')}');
    
    if (snapshot.containsKey('expense_tracker_expenses')) {
      final expenses = snapshot['expense_tracker_expenses'] as List<dynamic>? ?? [];
      print('[RESTORE] Found ${expenses.length} expense tracker expenses in snapshot');
      final expenseBox = Hive.box<expense_tracker_expense.ExpenseModel>(expense_tracker_constants.expenseTrackerBoxName);
      print('[RESTORE] Expense tracker box length before restore: ${expenseBox.length}');
      
      int restoredCount = 0;
      int skippedCount = 0;
      
      for (final e in expenses) {
        try {
          final m = e as Map<String, dynamic>;
          print('[RESTORE] Processing expense: id=${m['id']}, description=${m['description']}');
          
          // Parse date using date-only deserialization to preserve the date correctly
          final dateStr = _safeStringNullable(m, 'date');
          final expenseDate = dateStr != null 
              ? _deserializeDateOnlyRequired(dateStr)
              : DateTime.now();
          
          print('[RESTORE] Parsed expense date: original=$dateStr, parsed=$expenseDate');
          
          final model = expense_tracker_expense.ExpenseModel(
            id: _safeString(m, 'id', ''),
            date: expenseDate,
            description: _safeString(m, 'description', 'Unnamed Expense'),
            amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
            group: _safeString(m, 'group', 'food'), // Default to 'food' if missing
            createdAt: DateTime.tryParse(_safeString(m, 'createdAt', '')) ?? DateTime.now(),
            updatedAt: DateTime.tryParse(_safeString(m, 'updatedAt', '')) ?? DateTime.now(),
          );
          
          if (model.id.isEmpty) {
            print('[RESTORE] Skipping expense with empty ID');
            skippedCount++;
            continue; // Skip invalid entries
          }
          
          await expenseBox.put(model.id, model);
          restoredCount++;
          print('[RESTORE] Restored expense: id=${model.id}, description=${model.description}');
        } catch (e, stackTrace) {
          print('[RESTORE] Error restoring expense: $e');
          print('[RESTORE] Stack trace: $stackTrace');
          skippedCount++;
        }
      }
      
      print('[RESTORE] Expense tracker restore completed: restored=$restoredCount, skipped=$skippedCount');
      print('[RESTORE] Expense tracker box length after restore: ${expenseBox.length}');
    } else {
      print('[RESTORE] WARNING: No expense_tracker_expenses key found in snapshot!');
    }
    
    print('[RESTORE] Expense Tracker restore process completed');

    // ========================================================================
    // Retirement Planner Data (optional - only restore if present in backup)
    // ========================================================================
    if (snapshot.containsKey('retirement_plans')) {
      final retirementPlans = snapshot['retirement_plans'] as List<dynamic>? ?? [];
      final retirementPlanBox = Hive.box<RetirementPlanModel>(retirement_constants.retirementPlanBoxName);
      for (final rp in retirementPlans) {
        final m = rp as Map<String, dynamic>;
        final model = RetirementPlanModel(
          id: _safeString(m, 'id', ''),
          name: _safeString(m, 'name', 'Unnamed Plan'),
          dob: DateTime.tryParse(_safeString(m, 'dob', '')) ?? DateTime.now(),
          retirementAge: (m['retirementAge'] as num?)?.toInt() ?? 65,
          lifeExpectancy: (m['lifeExpectancy'] as num?)?.toInt() ?? 85,
          inflationRate: (m['inflationRate'] as num?)?.toDouble() ?? 0.0,
          postRetirementReturnRate: (m['postRetirementReturnRate'] as num?)?.toDouble() ?? 0.0,
          preRetirementReturnRate: (m['preRetirementReturnRate'] as num?)?.toDouble() ?? 0.0,
          preRetirementReturnRatioVariation: (m['preRetirementReturnRatioVariation'] as num?)?.toDouble() ?? 0.0,
          monthlyExpensesVariation: (m['monthlyExpensesVariation'] as num?)?.toDouble() ?? 0.0,
          currentMonthlyExpenses: (m['currentMonthlyExpenses'] as num?)?.toDouble() ?? 0.0,
          currentSavings: (m['currentSavings'] as num?)?.toDouble() ?? 0.0,
          periodForIncome: (m['periodForIncome'] as num?)?.toDouble(),
          preRetirementReturnRateCalculated: (m['preRetirementReturnRateCalculated'] as num?)?.toDouble(),
          monthlyExpensesAtRetirement: (m['monthlyExpensesAtRetirement'] as num?)?.toDouble(),
          totalCorpusNeeded: (m['totalCorpusNeeded'] as num?)?.toDouble(),
          futureValueOfCurrentInvestment: (m['futureValueOfCurrentInvestment'] as num?)?.toDouble(),
          corpusRequiredToBuild: (m['corpusRequiredToBuild'] as num?)?.toDouble(),
          monthlyInvestment: (m['monthlyInvestment'] as num?)?.toDouble(),
          yearlyInvestment: (m['yearlyInvestment'] as num?)?.toDouble(),
          createdAt: DateTime.tryParse(_safeString(m, 'createdAt', '')) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(_safeString(m, 'updatedAt', '')) ?? DateTime.now(),
        );
        if (model.id.isEmpty) continue; // Skip invalid entries
        await retirementPlanBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('retirement_preferences')) {
      final retirementPrefs = snapshot['retirement_preferences'] as Map<String, dynamic>? ?? {};
      final retirementPrefsBox = Hive.box(retirement_constants.retirementPreferencesBoxName);
      await retirementPrefsBox.clear();
      for (final entry in retirementPrefs.entries) {
        await retirementPrefsBox.put(entry.key, entry.value);
      }
    }

    // ========================================================================
    // App-wide Preferences (optional - don't fail if missing)
    // ========================================================================
    final viewPrefs = snapshot['view_preferences'] as Map<String, dynamic>? ?? {};
    final viewBox = Hive.box(goal_constants.viewPreferencesBoxName);
    await viewBox.clear();
    for (final entry in viewPrefs.entries) {
      final key = entry.key;
      final val = entry.value;
      if (val is String) {
        await viewBox.put(key, val);
      }
    }

    final filterPrefs = snapshot['filter_preferences'] as Map<String, dynamic>? ?? {};
    final filterBox = Hive.box(goal_constants.filterPreferencesBoxName);
    await filterBox.clear();
    for (final entry in filterPrefs.entries) {
      await filterBox.put(entry.key, entry.value);
    }

    final sortPrefs = snapshot['sort_preferences'] as Map<String, dynamic>? ?? {};
    final sortBox = Hive.box(goal_constants.sortPreferencesBoxName);
    await sortBox.clear();
    for (final entry in sortPrefs.entries) {
      await sortBox.put(entry.key, entry.value);
    }

    final themePrefs = snapshot['theme_preferences'] as Map<String, dynamic>? ?? {};
    final themeBox = Hive.box(goal_constants.themePreferencesBoxName);
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

