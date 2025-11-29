import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/services/box_provider.dart';
import 'package:all_tracker/core/constants/app_constants.dart';

const String _kGoalTrackerEnabled = 'goal_tracker_enabled';
const String _kTravelTrackerEnabled = 'travel_tracker_enabled';
const String _kInvestmentPlannerEnabled = 'investment_planner_enabled';
const String _kRetirementPlannerEnabled = 'retirement_planner_enabled';
const String _kDefaultHomePage = 'default_home_page';

class OrganizationPreferencesService {
  final BoxProvider boxes;

  OrganizationPreferencesService({BoxProvider? boxes}) : boxes = boxes ?? HiveBoxProvider();

  Future<void> init() async {
    if (!boxes.isBoxOpen(organizationPreferencesBoxName)) {
      await boxes.openBox(organizationPreferencesBoxName);
    }
  }

  Box<dynamic> get _box => boxes.box(organizationPreferencesBoxName);

  bool loadGoalTrackerEnabled() => (_box.get(_kGoalTrackerEnabled) as bool?) ?? true;
  bool loadTravelTrackerEnabled() => (_box.get(_kTravelTrackerEnabled) as bool?) ?? true;
  bool loadInvestmentPlannerEnabled() => (_box.get(_kInvestmentPlannerEnabled) as bool?) ?? true;
  bool loadRetirementPlannerEnabled() => (_box.get(_kRetirementPlannerEnabled) as bool?) ?? true;
  String loadDefaultHomePage() => (_box.get(_kDefaultHomePage) as String?) ?? 'app_home';

  Future<void> saveGoalTrackerEnabled(bool enabled) async => _box.put(_kGoalTrackerEnabled, enabled);
  Future<void> saveTravelTrackerEnabled(bool enabled) async => _box.put(_kTravelTrackerEnabled, enabled);
  Future<void> saveInvestmentPlannerEnabled(bool enabled) async => _box.put(_kInvestmentPlannerEnabled, enabled);
  Future<void> saveRetirementPlannerEnabled(bool enabled) async => _box.put(_kRetirementPlannerEnabled, enabled);
  Future<void> saveDefaultHomePage(String homePage) async => _box.put(_kDefaultHomePage, homePage);
}

