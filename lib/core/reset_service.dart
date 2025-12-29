/*
 * File: reset_service.dart
 *
 * Purpose:
 *   Service for resetting/clearing all data for specific trackers or utilities.
 *   This provides a clean slate by clearing all Hive boxes associated with a tracker/utility.
 *
 * Responsibilities:
 *   - Clear all data boxes for a specific tracker or utility
 *   - Provide a safe way to reset data without affecting other trackers
 *   - Handle all related boxes for each tracker/utility
 */

import 'package:hive/hive.dart';
import '../trackers/goal_tracker/core/constants.dart' as goal_constants;
import '../trackers/travel_tracker/core/constants.dart' as travel_constants;
import '../trackers/password_tracker/core/constants.dart' as password_constants;
import '../trackers/expense_tracker/core/constants.dart' as expense_tracker_constants;
import '../trackers/file_tracker/core/constants.dart' as file_tracker_constants;
import '../trackers/book_tracker/core/constants.dart' as book_tracker_constants;
import '../trackers/portfolio_tracker/core/constants.dart' as portfolio_tracker_constants;
import '../utilities/investment_planner/core/constants.dart' as investment_constants;
import '../utilities/retirement_planner/core/constants.dart' as retirement_constants;
import '../trackers/goal_tracker/data/models/goal_model.dart';
import '../trackers/goal_tracker/data/models/milestone_model.dart';
import '../trackers/goal_tracker/data/models/task_model.dart';
import '../trackers/goal_tracker/data/models/habit_model.dart';
import '../trackers/goal_tracker/data/models/habit_completion_model.dart';
import '../trackers/travel_tracker/data/models/trip_model.dart';
import '../trackers/travel_tracker/data/models/trip_profile_model.dart';
import '../trackers/travel_tracker/data/models/traveler_model.dart';
import '../trackers/travel_tracker/data/models/itinerary_day_model.dart';
import '../trackers/travel_tracker/data/models/itinerary_item_model.dart';
import '../trackers/travel_tracker/data/models/journal_entry_model.dart';
import '../trackers/travel_tracker/data/models/photo_model.dart';
import '../trackers/travel_tracker/data/models/expense_model.dart' as travel_expense;
import '../trackers/expense_tracker/data/models/expense_model.dart' as expense_tracker_expense;
import '../trackers/password_tracker/data/models/password_model.dart';
import '../trackers/password_tracker/data/models/secret_question_model.dart';
import '../trackers/file_tracker/data/models/file_server_config_model.dart';
import '../trackers/file_tracker/data/models/file_metadata_model.dart';
import '../trackers/book_tracker/data/models/book_model.dart';
import '../trackers/portfolio_tracker/data/models/investment_master_model.dart';
import '../trackers/portfolio_tracker/data/models/investment_log_model.dart';
import '../trackers/portfolio_tracker/data/models/redemption_log_model.dart';
import '../utilities/investment_planner/data/models/investment_component_model.dart';
import '../utilities/investment_planner/data/models/income_category_model.dart';
import '../utilities/investment_planner/data/models/expense_category_model.dart';
import '../utilities/investment_planner/data/models/investment_plan_model.dart';
import '../utilities/retirement_planner/data/models/retirement_plan_model.dart';

/// Enum representing all available trackers and utilities that can be reset.
enum ResetTarget {
  goalTracker,
  travelTracker,
  passwordTracker,
  expenseTracker,
  fileTracker,
  bookTracker,
  portfolioTracker,
  investmentPlanner,
  retirementPlanner,
}

/// Service for resetting tracker and utility data.
class ResetService {
  /// Resets all data for the specified tracker or utility.
  ///
  /// This clears all Hive boxes associated with the target, providing a clean slate.
  /// Returns true if successful, false otherwise.
  static Future<bool> resetData(ResetTarget target) async {
    try {
      switch (target) {
        case ResetTarget.goalTracker:
          await _resetGoalTracker();
          break;
        case ResetTarget.travelTracker:
          await _resetTravelTracker();
          break;
        case ResetTarget.passwordTracker:
          await _resetPasswordTracker();
          break;
        case ResetTarget.expenseTracker:
          await _resetExpenseTracker();
          break;
        case ResetTarget.fileTracker:
          await _resetFileTracker();
          break;
        case ResetTarget.bookTracker:
          await _resetBookTracker();
          break;
        case ResetTarget.portfolioTracker:
          await _resetPortfolioTracker();
          break;
        case ResetTarget.investmentPlanner:
          await _resetInvestmentPlanner();
          break;
        case ResetTarget.retirementPlanner:
          await _resetRetirementPlanner();
          break;
      }
      return true;
    } catch (e) {
      print('Error resetting ${target.name}: $e');
      return false;
    }
  }

  /// Gets the display name for a reset target.
  static String getDisplayName(ResetTarget target) {
    switch (target) {
      case ResetTarget.goalTracker:
        return 'Goal Tracker';
      case ResetTarget.travelTracker:
        return 'Travel Tracker';
      case ResetTarget.passwordTracker:
        return 'Password Tracker';
      case ResetTarget.expenseTracker:
        return 'Expense Tracker';
      case ResetTarget.fileTracker:
        return 'File Tracker';
      case ResetTarget.bookTracker:
        return 'Book Tracker';
      case ResetTarget.portfolioTracker:
        return 'Portfolio Tracker';
      case ResetTarget.investmentPlanner:
        return 'Investment Planner';
      case ResetTarget.retirementPlanner:
        return 'Retirement Planner';
    }
  }

  static Future<void> _resetGoalTracker() async {
    if (Hive.isBoxOpen(goal_constants.goalBoxName)) {
      await Hive.box<GoalModel>(goal_constants.goalBoxName).clear();
    }
    if (Hive.isBoxOpen(goal_constants.milestoneBoxName)) {
      await Hive.box<MilestoneModel>(goal_constants.milestoneBoxName).clear();
    }
    if (Hive.isBoxOpen(goal_constants.taskBoxName)) {
      await Hive.box<TaskModel>(goal_constants.taskBoxName).clear();
    }
    if (Hive.isBoxOpen(goal_constants.habitBoxName)) {
      await Hive.box<HabitModel>(goal_constants.habitBoxName).clear();
    }
    if (Hive.isBoxOpen(goal_constants.habitCompletionBoxName)) {
      await Hive.box<HabitCompletionModel>(goal_constants.habitCompletionBoxName).clear();
    }
  }

  static Future<void> _resetTravelTracker() async {
    if (Hive.isBoxOpen(travel_constants.tripBoxName)) {
      await Hive.box<TripModel>(travel_constants.tripBoxName).clear();
    }
    if (Hive.isBoxOpen(travel_constants.tripProfileBoxName)) {
      await Hive.box<TripProfileModel>(travel_constants.tripProfileBoxName).clear();
    }
    if (Hive.isBoxOpen(travel_constants.travelerBoxName)) {
      await Hive.box<TravelerModel>(travel_constants.travelerBoxName).clear();
    }
    if (Hive.isBoxOpen(travel_constants.itineraryDayBoxName)) {
      await Hive.box<ItineraryDayModel>(travel_constants.itineraryDayBoxName).clear();
    }
    if (Hive.isBoxOpen(travel_constants.itineraryItemBoxName)) {
      await Hive.box<ItineraryItemModel>(travel_constants.itineraryItemBoxName).clear();
    }
    if (Hive.isBoxOpen(travel_constants.journalEntryBoxName)) {
      await Hive.box<JournalEntryModel>(travel_constants.journalEntryBoxName).clear();
    }
    if (Hive.isBoxOpen(travel_constants.photoBoxName)) {
      await Hive.box<PhotoModel>(travel_constants.photoBoxName).clear();
    }
    if (Hive.isBoxOpen(travel_constants.expenseBoxName)) {
      await Hive.box<travel_expense.ExpenseModel>(travel_constants.expenseBoxName).clear();
    }
  }

  static Future<void> _resetPasswordTracker() async {
    if (Hive.isBoxOpen(password_constants.passwordBoxName)) {
      await Hive.box<PasswordModel>(password_constants.passwordBoxName).clear();
    }
    if (Hive.isBoxOpen(password_constants.secretQuestionBoxName)) {
      await Hive.box<SecretQuestionModel>(password_constants.secretQuestionBoxName).clear();
    }
  }

  static Future<void> _resetExpenseTracker() async {
    if (Hive.isBoxOpen(expense_tracker_constants.expenseTrackerBoxName)) {
      await Hive.box<expense_tracker_expense.ExpenseModel>(expense_tracker_constants.expenseTrackerBoxName).clear();
    }
  }

  static Future<void> _resetFileTracker() async {
    if (Hive.isBoxOpen(file_tracker_constants.fileTrackerConfigBoxName)) {
      await Hive.box<FileServerConfigModel>(file_tracker_constants.fileTrackerConfigBoxName).clear();
    }
    final activeBoxName = '${file_tracker_constants.fileTrackerConfigBoxName}_active';
    if (Hive.isBoxOpen(activeBoxName)) {
      await Hive.box<String>(activeBoxName).clear();
    }
    if (Hive.isBoxOpen(file_tracker_constants.fileTrackerMetadataBoxName)) {
      await Hive.box<FileMetadataModel>(file_tracker_constants.fileTrackerMetadataBoxName).clear();
    }
  }

  static Future<void> _resetBookTracker() async {
    if (Hive.isBoxOpen(book_tracker_constants.booksTrackerBoxName)) {
      final box = Hive.box<BookModel>(book_tracker_constants.booksTrackerBoxName);
      await box.clear();
      // Ensure the box is flushed to disk
      await box.flush();
    }
  }

  static Future<void> _resetPortfolioTracker() async {
    if (Hive.isBoxOpen(portfolio_tracker_constants.PortfolioTrackerConstants.investmentMastersBoxName)) {
      await Hive.box<InvestmentMasterModel>(portfolio_tracker_constants.PortfolioTrackerConstants.investmentMastersBoxName).clear();
    }
    if (Hive.isBoxOpen(portfolio_tracker_constants.PortfolioTrackerConstants.investmentLogsBoxName)) {
      await Hive.box<InvestmentLogModel>(portfolio_tracker_constants.PortfolioTrackerConstants.investmentLogsBoxName).clear();
    }
    if (Hive.isBoxOpen(portfolio_tracker_constants.PortfolioTrackerConstants.redemptionLogsBoxName)) {
      await Hive.box<RedemptionLogModel>(portfolio_tracker_constants.PortfolioTrackerConstants.redemptionLogsBoxName).clear();
    }
  }

  static Future<void> _resetInvestmentPlanner() async {
    if (Hive.isBoxOpen(investment_constants.investmentComponentBoxName)) {
      await Hive.box<InvestmentComponentModel>(investment_constants.investmentComponentBoxName).clear();
    }
    if (Hive.isBoxOpen(investment_constants.incomeCategoryBoxName)) {
      await Hive.box<IncomeCategoryModel>(investment_constants.incomeCategoryBoxName).clear();
    }
    if (Hive.isBoxOpen(investment_constants.expenseCategoryBoxName)) {
      await Hive.box<ExpenseCategoryModel>(investment_constants.expenseCategoryBoxName).clear();
    }
    if (Hive.isBoxOpen(investment_constants.investmentPlanBoxName)) {
      await Hive.box<InvestmentPlanModel>(investment_constants.investmentPlanBoxName).clear();
    }
  }

  static Future<void> _resetRetirementPlanner() async {
    if (Hive.isBoxOpen(retirement_constants.retirementPlanBoxName)) {
      await Hive.box<RetirementPlanModel>(retirement_constants.retirementPlanBoxName).clear();
    }
    if (Hive.isBoxOpen(retirement_constants.retirementPreferencesBoxName)) {
      await Hive.box(retirement_constants.retirementPreferencesBoxName).clear();
    }
  }
}

