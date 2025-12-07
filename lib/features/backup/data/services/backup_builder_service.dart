import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../trackers/goal_tracker/core/constants.dart' as goal_constants;
import '../../../../trackers/travel_tracker/core/constants.dart' as travel_constants;
import '../../../../trackers/password_tracker/core/constants.dart' as password_constants;
import '../../../../trackers/expense_tracker/core/constants.dart' as expense_tracker_constants;
import '../../../../utilities/investment_planner/core/constants.dart' as investment_constants;
import '../../../../utilities/retirement_planner/core/constants.dart' as retirement_constants;
import '../models/backup_manifest.dart';
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
import '../../../../utilities/retirement_planner/data/models/retirement_plan_model.dart';

/// Service for building backup snapshots from Hive data.
class BackupBuilderService {
  static const String _currentVersion = '1';
  static const int _currentDbSchemaVersion = 9; // Updated to include password tracker

  /// Serializes a date-only field to ISO string preserving the date component.
  /// 
  /// This extracts the date components (year, month, day) and creates a UTC
  /// DateTime at midnight with those components, ensuring the date is preserved
  /// correctly regardless of the original timezone. For example, if the user
  /// selected "2024-01-15", it will always be saved as "2024-01-15T00:00:00.000Z".
  static String? _serializeDateOnly(DateTime? date) {
    if (date == null) return null;
    // Extract date components from the local date (year, month, day)
    // Create UTC date at midnight with those components to preserve the date
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    return utcDate.toIso8601String();
  }

  /// Serializes a date-only field (non-nullable) to ISO string.
  static String _serializeDateOnlyRequired(DateTime date) {
    // Extract date components and create UTC date at midnight
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    return utcDate.toIso8601String();
  }

  /// Create a JSON snapshot of all Hive boxes.
  Future<Map<String, dynamic>> createBackupSnapshot() async {
    print('[BACKUP] Starting backup snapshot creation...');
    print('[BACKUP] Version: $_currentVersion, Schema Version: $_currentDbSchemaVersion');
    
    final snapshot = <String, dynamic>{
      'version': _currentVersion,
      'dbSchemaVersion': _currentDbSchemaVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    // ========================================================================
    // Goal Tracker Data
    // ========================================================================
    final goalsBox = Hive.box<GoalModel>(goal_constants.goalBoxName);
    snapshot['goals'] = goalsBox.values.map((g) => {
          'id': g.id,
          'name': g.name,
          'description': g.description,
          'targetDate': g.targetDate?.toUtc().toIso8601String(),
          'context': g.context,
          'isCompleted': g.isCompleted,
        }).toList();

    final milestonesBox = Hive.box<MilestoneModel>(goal_constants.milestoneBoxName);
    snapshot['milestones'] = milestonesBox.values.map((m) => {
          'id': m.id,
          'name': m.name,
          'description': m.description,
          'plannedValue': m.plannedValue,
          'actualValue': m.actualValue,
          'targetDate': m.targetDate?.toUtc().toIso8601String(),
          'goalId': m.goalId,
        }).toList();

    final tasksBox = Hive.box<TaskModel>(goal_constants.taskBoxName);
    snapshot['tasks'] = tasksBox.values.map((t) => {
          'id': t.id,
          'name': t.name,
          'targetDate': t.targetDate?.toUtc().toIso8601String(),
          'milestoneId': t.milestoneId,
          'goalId': t.goalId,
          'status': t.status,
        }).toList();

    final habitsBox = Hive.box<HabitModel>(goal_constants.habitBoxName);
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

    final completionsBox = Hive.box<HabitCompletionModel>(goal_constants.habitCompletionBoxName);
    snapshot['habit_completions'] = completionsBox.values.map((c) => {
          'id': c.id,
          'habitId': c.habitId,
          'completionDate': c.completionDate.toUtc().toIso8601String(),
          'note': c.note,
        }).toList();

    // ========================================================================
    // Travel Tracker Data
    // ========================================================================
    final tripsBox = Hive.box<TripModel>(travel_constants.tripBoxName);
    snapshot['trips'] = tripsBox.values.map((t) => {
          'id': t.id,
          'title': t.title,
          'destination': t.destination,
          'startDate': _serializeDateOnly(t.startDate),
          'endDate': _serializeDateOnly(t.endDate),
          'description': t.description,
          'tripTypeIndex': t.tripTypeIndex,
          'destinationLatitude': t.destinationLatitude,
          'destinationLongitude': t.destinationLongitude,
          'destinationMapLink': t.destinationMapLink,
          'createdAt': t.createdAt.toUtc().toIso8601String(),
          'updatedAt': t.updatedAt.toUtc().toIso8601String(),
        }).toList();

    final tripProfilesBox = Hive.box<TripProfileModel>(travel_constants.tripProfileBoxName);
    snapshot['trip_profiles'] = tripProfilesBox.values.map((tp) => {
          'id': tp.id,
          'tripId': tp.tripId,
          'travelerName': tp.travelerName,
          'email': tp.email,
          'notes': tp.notes,
          'createdAt': tp.createdAt.toUtc().toIso8601String(),
          'updatedAt': tp.updatedAt.toUtc().toIso8601String(),
        }).toList();

    final travelersBox = Hive.box<TravelerModel>(travel_constants.travelerBoxName);
    snapshot['travelers'] = travelersBox.values.map((t) => {
          'id': t.id,
          'tripId': t.tripId,
          'name': t.name,
          'relationship': t.relationship,
          'email': t.email,
          'phone': t.phone,
          'notes': t.notes,
          'isMainTraveler': t.isMainTraveler,
          'createdAt': t.createdAt.toUtc().toIso8601String(),
          'updatedAt': t.updatedAt.toUtc().toIso8601String(),
        }).toList();

    final itineraryDaysBox = Hive.box<ItineraryDayModel>(travel_constants.itineraryDayBoxName);
    snapshot['itinerary_days'] = itineraryDaysBox.values.map((id) => {
          'id': id.id,
          'tripId': id.tripId,
          'date': _serializeDateOnlyRequired(id.date),
          'createdAt': id.createdAt.toUtc().toIso8601String(),
          'updatedAt': id.updatedAt.toUtc().toIso8601String(),
        }).toList();

    final itineraryItemsBox = Hive.box<ItineraryItemModel>(travel_constants.itineraryItemBoxName);
    snapshot['itinerary_items'] = itineraryItemsBox.values.map((ii) => {
          'id': ii.id,
          'dayId': ii.dayId,
          'typeIndex': ii.typeIndex,
          'title': ii.title,
          'time': ii.time?.toUtc().toIso8601String(),
          'location': ii.location,
          'notes': ii.notes,
          'mapLink': ii.mapLink,
          'createdAt': ii.createdAt.toUtc().toIso8601String(),
          'updatedAt': ii.updatedAt.toUtc().toIso8601String(),
        }).toList();

    final journalEntriesBox = Hive.box<JournalEntryModel>(travel_constants.journalEntryBoxName);
    snapshot['journal_entries'] = journalEntriesBox.values.map((je) => {
          'id': je.id,
          'tripId': je.tripId,
          'date': je.date.toUtc().toIso8601String(),
          'content': je.content,
          'createdAt': je.createdAt.toUtc().toIso8601String(),
          'updatedAt': je.updatedAt.toUtc().toIso8601String(),
        }).toList();

    final photosBox = Hive.box<PhotoModel>(travel_constants.photoBoxName);
    snapshot['photos'] = photosBox.values.map((p) => {
          'id': p.id,
          'journalEntryId': p.journalEntryId,
          'filePath': p.filePath,
          'caption': p.caption,
          'dateTaken': p.dateTaken?.toUtc().toIso8601String(),
          'taggedDay': p.taggedDay?.toUtc().toIso8601String(),
          'taggedLocation': p.taggedLocation,
          'createdAt': p.createdAt.toUtc().toIso8601String(),
        }).toList();

    final expensesBox = Hive.box<travel_expense.ExpenseModel>(travel_constants.expenseBoxName);
    snapshot['expenses'] = expensesBox.values.map((e) => {
          'id': e.id,
          'tripId': e.tripId,
          'date': _serializeDateOnlyRequired(e.date),
          'categoryIndex': e.categoryIndex,
          'amount': e.amount,
          'currency': e.currency,
          'description': e.description,
          'paidBy': e.paidBy,
          'createdAt': e.createdAt.toUtc().toIso8601String(),
          'updatedAt': e.updatedAt.toUtc().toIso8601String(),
        }).toList();

    // ========================================================================
    // Investment Planner Data
    // ========================================================================
    final investmentComponentsBox = Hive.box<InvestmentComponentModel>(investment_constants.investmentComponentBoxName);
    snapshot['investment_components'] = investmentComponentsBox.values.map((ic) => {
          'id': ic.id,
          'name': ic.name,
          'percentage': ic.percentage,
          'minLimit': ic.minLimit,
          'maxLimit': ic.maxLimit,
          'priority': ic.priority,
        }).toList();

    final incomeCategoriesBox = Hive.box<IncomeCategoryModel>(investment_constants.incomeCategoryBoxName);
    snapshot['income_categories'] = incomeCategoriesBox.values.map((ic) => {
          'id': ic.id,
          'name': ic.name,
        }).toList();

    final expenseCategoriesBox = Hive.box<ExpenseCategoryModel>(investment_constants.expenseCategoryBoxName);
    snapshot['expense_categories'] = expenseCategoriesBox.values.map((ec) => {
          'id': ec.id,
          'name': ec.name,
        }).toList();

    final investmentPlansBox = Hive.box<InvestmentPlanModel>(investment_constants.investmentPlanBoxName);
    snapshot['investment_plans'] = investmentPlansBox.values.map((ip) => {
          'id': ip.id,
          'name': ip.name,
          'incomeEntries': ip.incomeEntries.map((ie) => {
                'id': ie.id,
                'categoryId': ie.categoryId,
                'amount': ie.amount,
              }).toList(),
          'expenseEntries': ip.expenseEntries.map((ee) => {
                'id': ee.id,
                'categoryId': ee.categoryId,
                'amount': ee.amount,
              }).toList(),
          'allocations': ip.allocations.map((a) => {
                'componentId': a.componentId,
                'allocatedAmount': a.allocatedAmount,
              }).toList(),
          'createdAt': ip.createdAt.toUtc().toIso8601String(),
          'updatedAt': ip.updatedAt.toUtc().toIso8601String(),
        }).toList();

    // ========================================================================
    // Password Tracker Data
    // ========================================================================
    final passwordsBox = Hive.box<PasswordModel>(password_constants.passwordBoxName);
    
    snapshot['passwords'] = passwordsBox.values.map((p) {
      return {
        'id': p.id,
        'siteName': p.siteName,
        'url': p.url,
        'username': p.username,
        'encryptedPassword': p.encryptedPassword, // Store encrypted as-is
        'isGoogleSignIn': p.isGoogleSignIn,
        'lastUpdated': p.lastUpdated.toUtc().toIso8601String(),
        'is2FA': p.is2FA,
        'categoryGroup': p.categoryGroup,
        'hasSecretQuestions': p.hasSecretQuestions,
      };
    }).toList();

    final secretQuestionsBox = Hive.box<SecretQuestionModel>(password_constants.secretQuestionBoxName);
    
    snapshot['secret_questions'] = secretQuestionsBox.values.map((sq) {
      return {
        'id': sq.id,
        'passwordId': sq.passwordId,
        'question': sq.question,
        'encryptedAnswer': sq.encryptedAnswer, // Store encrypted as-is
      };
    }).toList();

    // ========================================================================
    // Expense Tracker Data
    // ========================================================================
    final expenseTrackerBox = Hive.box<expense_tracker_expense.ExpenseModel>(expense_tracker_constants.expenseTrackerBoxName);
    
    snapshot['expense_tracker_expenses'] = expenseTrackerBox.values.map((e) {
      // Extract date components and create UTC date at midnight to preserve the date correctly
      final dateOnly = _serializeDateOnlyRequired(e.date);
      return {
        'id': e.id,
        'date': dateOnly,
        'description': e.description,
        'amount': e.amount,
        'group': e.group,
        'createdAt': e.createdAt.toUtc().toIso8601String(),
        'updatedAt': e.updatedAt.toUtc().toIso8601String(),
      };
    }).toList();

    // ========================================================================
    // Retirement Planner Data
    // ========================================================================
    final retirementPlansBox = Hive.box<RetirementPlanModel>(retirement_constants.retirementPlanBoxName);
    snapshot['retirement_plans'] = retirementPlansBox.values.map((rp) => {
          'id': rp.id,
          'name': rp.name,
          'dob': rp.dob.toUtc().toIso8601String(),
          'retirementAge': rp.retirementAge,
          'lifeExpectancy': rp.lifeExpectancy,
          'inflationRate': rp.inflationRate,
          'postRetirementReturnRate': rp.postRetirementReturnRate,
          'preRetirementReturnRate': rp.preRetirementReturnRate,
          'preRetirementReturnRatioVariation': rp.preRetirementReturnRatioVariation,
          'monthlyExpensesVariation': rp.monthlyExpensesVariation,
          'currentMonthlyExpenses': rp.currentMonthlyExpenses,
          'currentSavings': rp.currentSavings,
          'periodForIncome': rp.periodForIncome,
          'preRetirementReturnRateCalculated': rp.preRetirementReturnRateCalculated,
          'monthlyExpensesAtRetirement': rp.monthlyExpensesAtRetirement,
          'totalCorpusNeeded': rp.totalCorpusNeeded,
          'futureValueOfCurrentInvestment': rp.futureValueOfCurrentInvestment,
          'corpusRequiredToBuild': rp.corpusRequiredToBuild,
          'monthlyInvestment': rp.monthlyInvestment,
          'yearlyInvestment': rp.yearlyInvestment,
          'createdAt': rp.createdAt.toUtc().toIso8601String(),
          'updatedAt': rp.updatedAt.toUtc().toIso8601String(),
        }).toList();

    final retirementPrefsBox = Hive.box(retirement_constants.retirementPreferencesBoxName);
    snapshot['retirement_preferences'] = _exportPreferences(retirementPrefsBox);

    // ========================================================================
    // App-wide Preferences
    // ========================================================================
    final viewPrefsBox = Hive.box(goal_constants.viewPreferencesBoxName);
    snapshot['view_preferences'] = _exportPreferences(viewPrefsBox);

    final filterPrefsBox = Hive.box(goal_constants.filterPreferencesBoxName);
    snapshot['filter_preferences'] = _exportPreferences(filterPrefsBox);

    final sortPrefsBox = Hive.box(goal_constants.sortPreferencesBoxName);
    snapshot['sort_preferences'] = _exportPreferences(sortPrefsBox);

    final themeBox = Hive.box(goal_constants.themePreferencesBoxName);
    snapshot['theme_preferences'] = {
      'theme_key': themeBox.get('theme_key'),
      'font_key': themeBox.get('font_key'),
      'is_dark': themeBox.get('is_dark'),
    };

    // Log summary of what was included in the backup
    print('[BACKUP] Backup snapshot creation completed');
    print('[BACKUP] Summary:');
    print('[BACKUP]   - Goals: ${(snapshot['goals'] as List).length}');
    print('[BACKUP]   - Milestones: ${(snapshot['milestones'] as List).length}');
    print('[BACKUP]   - Tasks: ${(snapshot['tasks'] as List).length}');
    print('[BACKUP]   - Habits: ${(snapshot['habits'] as List).length}');
    print('[BACKUP]   - Trips: ${(snapshot['trips'] as List).length}');
    print('[BACKUP]   - Passwords: ${(snapshot['passwords'] as List).length}');
    print('[BACKUP]   - Secret Questions: ${(snapshot['secret_questions'] as List).length}');
    print('[BACKUP]   - Expense Tracker Expenses: ${(snapshot['expense_tracker_expenses'] as List).length}');
    print('[BACKUP]   - Investment Plans: ${(snapshot['investment_plans'] as List).length}');
    print('[BACKUP]   - Retirement Plans: ${(snapshot['retirement_plans'] as List).length}');

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
      appVersion: '1.0.0', 
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

