import 'package:flutter/material.dart';
import 'organization_preferences_service.dart';

/// Notifier for managing organization preferences (tracker/utility visibility and default home page).
///
/// This notifier manages:
/// - Visibility toggles for trackers (Goal Tracker, Travel Tracker)
/// - Visibility toggles for utilities (Investment Planner, Retirement Planner)
/// - Default home page selection
///
/// When a tracker/utility is disabled and it was the default home page,
/// the default is automatically reset to 'app_home'.
class OrganizationNotifier extends ChangeNotifier {
  final OrganizationPreferencesService _prefs = OrganizationPreferencesService();

  bool _goalTrackerEnabled = true;
  bool _travelTrackerEnabled = true;
  bool _investmentPlannerEnabled = true;
  bool _retirementPlannerEnabled = true;
  String _defaultHomePage = 'app_home';

  Future<void> init() async {
    await _prefs.init();
    _goalTrackerEnabled = _prefs.loadGoalTrackerEnabled();
    _travelTrackerEnabled = _prefs.loadTravelTrackerEnabled();
    _investmentPlannerEnabled = _prefs.loadInvestmentPlannerEnabled();
    _retirementPlannerEnabled = _prefs.loadRetirementPlannerEnabled();
    _defaultHomePage = _prefs.loadDefaultHomePage();
    
    // Validate default home page - if it's disabled, reset to app_home
    if (!_isHomePageEnabled(_defaultHomePage)) {
      _defaultHomePage = 'app_home';
      await _prefs.saveDefaultHomePage(_defaultHomePage);
    }
    
    notifyListeners();
  }

  bool get goalTrackerEnabled => _goalTrackerEnabled;
  bool get travelTrackerEnabled => _travelTrackerEnabled;
  bool get investmentPlannerEnabled => _investmentPlannerEnabled;
  bool get retirementPlannerEnabled => _retirementPlannerEnabled;
  String get defaultHomePage => _defaultHomePage;

  /// Check if a home page option is currently enabled
  bool _isHomePageEnabled(String homePage) {
    switch (homePage) {
      case 'app_home':
        return true; // Always enabled
      case 'goal_tracker':
        return _goalTrackerEnabled;
      case 'travel_tracker':
        return _travelTrackerEnabled;
      case 'investment_planner':
        return _investmentPlannerEnabled;
      case 'retirement_planner':
        return _retirementPlannerEnabled;
      default:
        return false;
    }
  }

  /// Get list of enabled home page options
  List<String> getEnabledHomePageOptions() {
    final options = <String>['app_home'];
    if (_goalTrackerEnabled) options.add('goal_tracker');
    if (_travelTrackerEnabled) options.add('travel_tracker');
    if (_investmentPlannerEnabled) options.add('investment_planner');
    if (_retirementPlannerEnabled) options.add('retirement_planner');
    return options;
  }

  Future<void> setGoalTrackerEnabled(bool enabled) async {
    _goalTrackerEnabled = enabled;
    await _prefs.saveGoalTrackerEnabled(enabled);
    
    // If this was the default home page and it's being disabled, reset to app_home
    if (!enabled && _defaultHomePage == 'goal_tracker') {
      _defaultHomePage = 'app_home';
      await _prefs.saveDefaultHomePage(_defaultHomePage);
    }
    
    notifyListeners();
  }

  Future<void> setTravelTrackerEnabled(bool enabled) async {
    _travelTrackerEnabled = enabled;
    await _prefs.saveTravelTrackerEnabled(enabled);
    
    // If this was the default home page and it's being disabled, reset to app_home
    if (!enabled && _defaultHomePage == 'travel_tracker') {
      _defaultHomePage = 'app_home';
      await _prefs.saveDefaultHomePage(_defaultHomePage);
    }
    
    notifyListeners();
  }

  Future<void> setInvestmentPlannerEnabled(bool enabled) async {
    _investmentPlannerEnabled = enabled;
    await _prefs.saveInvestmentPlannerEnabled(enabled);
    
    // If this was the default home page and it's being disabled, reset to app_home
    if (!enabled && _defaultHomePage == 'investment_planner') {
      _defaultHomePage = 'app_home';
      await _prefs.saveDefaultHomePage(_defaultHomePage);
    }
    
    notifyListeners();
  }

  Future<void> setRetirementPlannerEnabled(bool enabled) async {
    _retirementPlannerEnabled = enabled;
    await _prefs.saveRetirementPlannerEnabled(enabled);
    
    // If this was the default home page and it's being disabled, reset to app_home
    if (!enabled && _defaultHomePage == 'retirement_planner') {
      _defaultHomePage = 'app_home';
      await _prefs.saveDefaultHomePage(_defaultHomePage);
    }
    
    notifyListeners();
  }

  Future<void> setDefaultHomePage(String homePage) async {
    // Only allow setting to enabled options
    if (!_isHomePageEnabled(homePage)) {
      return;
    }
    
    _defaultHomePage = homePage;
    await _prefs.saveDefaultHomePage(homePage);
    notifyListeners();
  }
}

