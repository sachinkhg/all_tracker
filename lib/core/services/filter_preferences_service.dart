import 'package:flutter/foundation.dart';
import 'package:all_tracker/core/services/box_provider.dart';
import 'package:all_tracker/core/services/view_entity_type.dart';
import 'package:all_tracker/core/constants/app_constants.dart';

/// FilterPreferencesService
///
/// File purpose:
/// - Manages persistence of filter preferences for Goals, Milestones, Tasks, etc.
/// - Similar to ViewPreferencesService but for filter settings.
/// - Stores filter preferences in Hive box for persistence across app sessions.
///
/// Usage:
/// - Save filter preferences when user checks "Save Filter" checkbox
/// - Load saved preferences when cubits initialize
/// - Clear preferences when user unchecks "Save Filter"
///
/// Storage format:
/// - Keys: 'goal_filters', 'milestone_filters', 'task_filters', etc.
/// - Values: Map<String, String?> containing filter key-value pairs
class FilterPreferencesService {
  final BoxProvider boxes;

  FilterPreferencesService({BoxProvider? boxes}) : boxes = boxes ?? HiveBoxProvider();
  
  /// Save filter preferences for a specific entity type
  Future<void> saveFilterPreferences(FilterEntityType entityType, Map<String, String?> filters) async {
    try {
      final box = boxes.box(filterPreferencesBoxName);
      final key = _getKeyForEntity(entityType);
      await box.put(key, filters);
    } catch (e) {
      // Handle error silently or log as needed
      debugPrint('Error saving filter preferences: $e');
    }
  }

  /// Load saved filter preferences for a specific entity type
  Map<String, String?>? loadFilterPreferences(FilterEntityType entityType) {
    try {
      final box = boxes.box(filterPreferencesBoxName);
      final key = _getKeyForEntity(entityType);
      final saved = box.get(key);
      return saved != null ? Map<String, String?>.from(saved) : null;
    } catch (e) {
      // Handle error silently or log as needed
      debugPrint('Error loading filter preferences: $e');
      return null;
    }
  }

  /// Clear filter preferences for a specific entity type
  Future<void> clearFilterPreferences(FilterEntityType entityType) async {
    try {
      final box = boxes.box(filterPreferencesBoxName);
      final key = _getKeyForEntity(entityType);
      await box.delete(key);
    } catch (e) {
      // Handle error silently or log as needed
      debugPrint('Error clearing filter preferences: $e');
    }
  }

  /// Get the storage key for a specific entity type
  String _getKeyForEntity(FilterEntityType entityType) {
    switch (entityType) {
      case FilterEntityType.goal:
        return 'goal_filters';
      case FilterEntityType.milestone:
        return 'milestone_filters';
      case FilterEntityType.task:
        return 'task_filters';
      case FilterEntityType.habit:
        return 'habit_filters';
      case FilterEntityType.itinerary:
        return 'itinerary_filters';
      case FilterEntityType.trip:
        return 'trip_filters';
    }
  }
}

