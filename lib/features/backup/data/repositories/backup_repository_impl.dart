import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../../../trackers/goal_tracker/core/constants.dart' as goal_constants;
import '../../../../trackers/travel_tracker/core/constants.dart' as travel_constants;
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
import '../../../../trackers/travel_tracker/data/models/expense_model.dart';
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
        'schemaVersion': '8',
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
      id: file['id'] as String,
      fileName: file['name'] as String? ?? 'unknown',
      createdAt: _parseDriveDate(file['createdTime'] as String?),
      deviceId: file['appProperties']?['deviceId'] as String? ?? 'unknown',
      sizeBytes: int.tryParse(file['size'] as String? ?? '0') ?? 0,
      isE2EE: file['appProperties']?['isE2EE'] == 'true',
      deviceDescription: null,
      name: file['appProperties']?['backupName'] as String?,
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
    await Hive.box<ExpenseModel>(travel_constants.expenseBoxName).clear();
    
    // Investment Planner boxes
    await Hive.box<InvestmentComponentModel>(investment_constants.investmentComponentBoxName).clear();
    await Hive.box<IncomeCategoryModel>(investment_constants.incomeCategoryBoxName).clear();
    await Hive.box<ExpenseCategoryModel>(investment_constants.expenseCategoryBoxName).clear();
    await Hive.box<InvestmentPlanModel>(investment_constants.investmentPlanBoxName).clear();
    
    // Retirement Planner boxes
    await Hive.box<RetirementPlanModel>(retirement_constants.retirementPlanBoxName).clear();
    await Hive.box(retirement_constants.retirementPreferencesBoxName).clear();
    
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

  Future<void> _importData(Map<String, dynamic> snapshot) async {
    // ========================================================================
    // Goal Tracker Data
    // ========================================================================
    final goals = snapshot['goals'] as List<dynamic>? ?? [];
    final goalBox = Hive.box<GoalModel>(goal_constants.goalBoxName);
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

    final milestones = snapshot['milestones'] as List<dynamic>? ?? [];
    final milestoneBox = Hive.box<MilestoneModel>(goal_constants.milestoneBoxName);
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

    final tasks = snapshot['tasks'] as List<dynamic>? ?? [];
    final taskBox = Hive.box<TaskModel>(goal_constants.taskBoxName);
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

    final habits = snapshot['habits'] as List<dynamic>? ?? [];
    final habitBox = Hive.box<HabitModel>(goal_constants.habitBoxName);
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

    final completions = snapshot['habit_completions'] as List<dynamic>? ?? [];
    final completionBox = Hive.box<HabitCompletionModel>(goal_constants.habitCompletionBoxName);
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

    // ========================================================================
    // Travel Tracker Data (optional - only restore if present in backup)
    // ========================================================================
    if (snapshot.containsKey('trips')) {
      final trips = snapshot['trips'] as List<dynamic>? ?? [];
      final tripBox = Hive.box<TripModel>(travel_constants.tripBoxName);
      for (final t in trips) {
        final m = t as Map<String, dynamic>;
        final model = TripModel(
          id: m['id'] as String,
          title: m['title'] as String,
          destination: m['destination'] as String?,
          startDate: _deserializeDateOnly(m['startDate'] as String?),
          endDate: _deserializeDateOnly(m['endDate'] as String?),
          description: m['description'] as String?,
          createdAt: DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(m['updatedAt'] as String) ?? DateTime.now(),
        );
        await tripBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('trip_profiles')) {
      final tripProfiles = snapshot['trip_profiles'] as List<dynamic>? ?? [];
      final tripProfileBox = Hive.box<TripProfileModel>(travel_constants.tripProfileBoxName);
      for (final tp in tripProfiles) {
        final m = tp as Map<String, dynamic>;
        final model = TripProfileModel(
          id: m['id'] as String,
          tripId: m['tripId'] as String,
          travelerName: m['travelerName'] as String?,
          email: m['email'] as String?,
          notes: m['notes'] as String?,
          createdAt: DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(m['updatedAt'] as String) ?? DateTime.now(),
        );
        await tripProfileBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('travelers')) {
      final travelers = snapshot['travelers'] as List<dynamic>? ?? [];
      final travelerBox = Hive.box<TravelerModel>(travel_constants.travelerBoxName);
      for (final t in travelers) {
        final m = t as Map<String, dynamic>;
        final model = TravelerModel(
          id: m['id'] as String,
          tripId: m['tripId'] as String,
          name: m['name'] as String,
          relationship: m['relationship'] as String?,
          email: m['email'] as String?,
          phone: m['phone'] as String?,
          notes: m['notes'] as String?,
          isMainTraveler: (m['isMainTraveler'] as bool?) ?? false,
          createdAt: DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(m['updatedAt'] as String) ?? DateTime.now(),
        );
        await travelerBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('itinerary_days')) {
      final itineraryDays = snapshot['itinerary_days'] as List<dynamic>? ?? [];
      final itineraryDayBox = Hive.box<ItineraryDayModel>(travel_constants.itineraryDayBoxName);
      for (final id in itineraryDays) {
        final m = id as Map<String, dynamic>;
        final model = ItineraryDayModel(
          id: m['id'] as String,
          tripId: m['tripId'] as String,
          date: _deserializeDateOnlyRequired(m['date'] as String),
          createdAt: DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(m['updatedAt'] as String) ?? DateTime.now(),
        );
        await itineraryDayBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('itinerary_items')) {
      final itineraryItems = snapshot['itinerary_items'] as List<dynamic>? ?? [];
      final itineraryItemBox = Hive.box<ItineraryItemModel>(travel_constants.itineraryItemBoxName);
      for (final ii in itineraryItems) {
        final m = ii as Map<String, dynamic>;
        final model = ItineraryItemModel(
          id: m['id'] as String,
          dayId: m['dayId'] as String,
          typeIndex: (m['typeIndex'] as num?)?.toInt() ?? 0,
          title: m['title'] as String,
          time: (m['time'] != null) ? DateTime.tryParse(m['time'] as String) : null,
          location: m['location'] as String?,
          notes: m['notes'] as String?,
          mapLink: m['mapLink'] as String?,
          createdAt: DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(m['updatedAt'] as String) ?? DateTime.now(),
        );
        await itineraryItemBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('journal_entries')) {
      final journalEntries = snapshot['journal_entries'] as List<dynamic>? ?? [];
      final journalEntryBox = Hive.box<JournalEntryModel>(travel_constants.journalEntryBoxName);
      for (final je in journalEntries) {
        final m = je as Map<String, dynamic>;
        final model = JournalEntryModel(
          id: m['id'] as String,
          tripId: m['tripId'] as String,
          date: DateTime.tryParse(m['date'] as String) ?? DateTime.now(),
          content: m['content'] as String,
          createdAt: DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(m['updatedAt'] as String) ?? DateTime.now(),
        );
        await journalEntryBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('photos')) {
      final photos = snapshot['photos'] as List<dynamic>? ?? [];
      final photoBox = Hive.box<PhotoModel>(travel_constants.photoBoxName);
      for (final p in photos) {
        final m = p as Map<String, dynamic>;
        final model = PhotoModel(
          id: m['id'] as String,
          journalEntryId: m['journalEntryId'] as String,
          filePath: m['filePath'] as String,
          caption: m['caption'] as String?,
          dateTaken: (m['dateTaken'] != null) ? DateTime.tryParse(m['dateTaken'] as String) : null,
          taggedDay: (m['taggedDay'] != null) ? DateTime.tryParse(m['taggedDay'] as String) : null,
          taggedLocation: m['taggedLocation'] as String?,
          createdAt: DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now(),
        );
        await photoBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('expenses')) {
      final expenses = snapshot['expenses'] as List<dynamic>? ?? [];
      final expenseBox = Hive.box<ExpenseModel>(travel_constants.expenseBoxName);
      for (final e in expenses) {
        final m = e as Map<String, dynamic>;
        final model = ExpenseModel(
          id: m['id'] as String,
          tripId: m['tripId'] as String,
          date: _deserializeDateOnlyRequired(m['date'] as String),
          categoryIndex: (m['categoryIndex'] as num?)?.toInt() ?? 0,
          amount: (m['amount'] as num).toDouble(),
          currency: m['currency'] as String,
          description: m['description'] as String?,
          createdAt: DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(m['updatedAt'] as String) ?? DateTime.now(),
        );
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
          id: m['id'] as String,
          name: m['name'] as String,
          percentage: (m['percentage'] as num).toDouble(),
          minLimit: (m['minLimit'] as num?)?.toDouble(),
          maxLimit: (m['maxLimit'] as num?)?.toDouble(),
          priority: (m['priority'] as num?)?.toInt() ?? 0,
        );
        await componentBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('income_categories')) {
      final incomeCategories = snapshot['income_categories'] as List<dynamic>? ?? [];
      final incomeCategoryBox = Hive.box<IncomeCategoryModel>(investment_constants.incomeCategoryBoxName);
      for (final ic in incomeCategories) {
        final m = ic as Map<String, dynamic>;
        final model = IncomeCategoryModel(
          id: m['id'] as String,
          name: m['name'] as String,
        );
        await incomeCategoryBox.put(model.id, model);
      }
    }

    if (snapshot.containsKey('expense_categories')) {
      final expenseCategories = snapshot['expense_categories'] as List<dynamic>? ?? [];
      final expenseCategoryBox = Hive.box<ExpenseCategoryModel>(investment_constants.expenseCategoryBoxName);
      for (final ec in expenseCategories) {
        final m = ec as Map<String, dynamic>;
        final model = ExpenseCategoryModel(
          id: m['id'] as String,
          name: m['name'] as String,
        );
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
            id: im['id'] as String,
            categoryId: im['categoryId'] as String,
            amount: (im['amount'] as num).toDouble(),
          );
        }).toList();
        final expenseEntries = (m['expenseEntries'] as List<dynamic>? ?? []).map((ee) {
          final em = ee as Map<String, dynamic>;
          return ExpenseEntryModel(
            id: em['id'] as String,
            categoryId: em['categoryId'] as String,
            amount: (em['amount'] as num).toDouble(),
          );
        }).toList();
        final allocations = (m['allocations'] as List<dynamic>? ?? []).map((a) {
          final am = a as Map<String, dynamic>;
          return ComponentAllocationModel(
            componentId: am['componentId'] as String,
            allocatedAmount: (am['allocatedAmount'] as num).toDouble(),
          );
        }).toList();
        final model = InvestmentPlanModel(
          id: m['id'] as String,
          name: m['name'] as String,
          duration: m['duration'] as String,
          period: m['period'] as String,
          incomeEntries: incomeEntries,
          expenseEntries: expenseEntries,
          allocations: allocations,
          createdAt: DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(m['updatedAt'] as String) ?? DateTime.now(),
        );
        await investmentPlanBox.put(model.id, model);
      }
    }

    // ========================================================================
    // Retirement Planner Data (optional - only restore if present in backup)
    // ========================================================================
    if (snapshot.containsKey('retirement_plans')) {
      final retirementPlans = snapshot['retirement_plans'] as List<dynamic>? ?? [];
      final retirementPlanBox = Hive.box<RetirementPlanModel>(retirement_constants.retirementPlanBoxName);
      for (final rp in retirementPlans) {
        final m = rp as Map<String, dynamic>;
        final model = RetirementPlanModel(
          id: m['id'] as String,
          name: m['name'] as String,
          dob: DateTime.tryParse(m['dob'] as String) ?? DateTime.now(),
          retirementAge: m['retirementAge'] as int,
          lifeExpectancy: m['lifeExpectancy'] as int,
          inflationRate: (m['inflationRate'] as num).toDouble(),
          postRetirementReturnRate: (m['postRetirementReturnRate'] as num).toDouble(),
          preRetirementReturnRate: (m['preRetirementReturnRate'] as num).toDouble(),
          preRetirementReturnRatioVariation: (m['preRetirementReturnRatioVariation'] as num).toDouble(),
          monthlyExpensesVariation: (m['monthlyExpensesVariation'] as num).toDouble(),
          currentMonthlyExpenses: (m['currentMonthlyExpenses'] as num).toDouble(),
          currentSavings: (m['currentSavings'] as num).toDouble(),
          periodForIncome: (m['periodForIncome'] as num?)?.toDouble(),
          preRetirementReturnRateCalculated: (m['preRetirementReturnRateCalculated'] as num?)?.toDouble(),
          monthlyExpensesAtRetirement: (m['monthlyExpensesAtRetirement'] as num?)?.toDouble(),
          totalCorpusNeeded: (m['totalCorpusNeeded'] as num?)?.toDouble(),
          futureValueOfCurrentInvestment: (m['futureValueOfCurrentInvestment'] as num?)?.toDouble(),
          corpusRequiredToBuild: (m['corpusRequiredToBuild'] as num?)?.toDouble(),
          monthlyInvestment: (m['monthlyInvestment'] as num?)?.toDouble(),
          yearlyInvestment: (m['yearlyInvestment'] as num?)?.toDouble(),
          createdAt: DateTime.tryParse(m['createdAt'] as String) ?? DateTime.now(),
          updatedAt: DateTime.tryParse(m['updatedAt'] as String) ?? DateTime.now(),
        );
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

