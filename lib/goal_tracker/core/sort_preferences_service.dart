import 'package:hive_flutter/hive_flutter.dart';
import 'constants.dart';

/// ---------------------------------------------------------------------------
/// SortPreferencesService
///
/// File purpose:
/// - Manages persistence of sort preferences for Goals, Milestones, and Tasks.
/// - Similar to FilterPreferencesService but for sort settings.
/// - Stores sort preferences in Hive box for persistence across app sessions.
///
/// Usage:
/// - Save sort preferences when user checks "Save Sort" checkbox
/// - Load saved preferences when cubits initialize
/// - Clear preferences when user unchecks "Save Sort"
///
/// Storage format:
/// - Keys: 'goal_sort', 'milestone_sort', 'task_sort'
/// - Values: Map<String, dynamic> containing sort order and hide completed settings
/// ---------------------------------------------------------------------------

class SortPreferencesService {
  /// Save sort preferences for a specific entity type
  Future<void> saveSortPreferences(SortEntityType entityType, Map<String, dynamic> sortSettings) async {
    try {
      final box = Hive.box(sortPreferencesBoxName);
      final key = _getKeyForEntity(entityType);
      await box.put(key, sortSettings);
    } catch (e) {
      // Handle error silently or log as needed
      print('Error saving sort preferences: $e');
    }
  }

  /// Load saved sort preferences for a specific entity type
  Map<String, dynamic>? loadSortPreferences(SortEntityType entityType) {
    try {
      final box = Hive.box(sortPreferencesBoxName);
      final key = _getKeyForEntity(entityType);
      final saved = box.get(key);
      return saved != null ? Map<String, dynamic>.from(saved) : null;
    } catch (e) {
      // Handle error silently or log as needed
      print('Error loading sort preferences: $e');
      return null;
    }
  }

  /// Clear sort preferences for a specific entity type
  Future<void> clearSortPreferences(SortEntityType entityType) async {
    try {
      final box = Hive.box(sortPreferencesBoxName);
      final key = _getKeyForEntity(entityType);
      await box.delete(key);
    } catch (e) {
      // Handle error silently or log as needed
      print('Error clearing sort preferences: $e');
    }
  }

  /// Get the storage key for a specific entity type
  String _getKeyForEntity(SortEntityType entityType) {
    switch (entityType) {
      case SortEntityType.goal:
        return 'goal_sort';
      case SortEntityType.milestone:
        return 'milestone_sort';
      case SortEntityType.task:
        return 'task_sort';
    }
  }
}

enum SortEntityType { goal, milestone, task }
