import 'package:hive_flutter/hive_flutter.dart';
import 'package:all_tracker/core/hive/hive_module_initializer.dart';
import 'package:all_tracker/core/constants/app_constants.dart';

/// Hive initializer for app-wide preference boxes.
///
/// This initializer handles opening preference boxes that are shared
/// across multiple modules (view preferences, filter preferences, etc.).
/// These boxes don't have specific models and use dynamic values.
class AppPreferencesHiveInitializer implements HiveModuleInitializer {
  @override
  Future<void> registerAdapters() async {
    // No adapters needed for preference boxes (they use dynamic values)
  }

  @override
  Future<void> openBoxes() async {
    // Open shared preference boxes
    await Hive.openBox(viewPreferencesBoxName);
    await Hive.openBox(filterPreferencesBoxName);
    await Hive.openBox(sortPreferencesBoxName);
    await Hive.openBox(themePreferencesBoxName);
    await Hive.openBox(organizationPreferencesBoxName);
  }
}

