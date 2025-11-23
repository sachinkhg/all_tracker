import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/itinerary_day.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../core/constants.dart';
import '../../domain/usecases/itinerary/create_itinerary_day.dart';
import '../../domain/usecases/itinerary/get_days_by_trip_id.dart';
import '../../domain/usecases/itinerary/update_itinerary_day.dart';
import '../../domain/usecases/itinerary/delete_itinerary_day.dart';
import '../../domain/usecases/itinerary/create_itinerary_item.dart';
import '../../domain/usecases/itinerary/get_items_by_day_id.dart';
import '../../domain/usecases/itinerary/update_itinerary_item.dart';
import '../../domain/usecases/itinerary/delete_itinerary_item.dart';
import '../../domain/usecases/trip/get_trip_by_id.dart';
import '../../../goal_tracker/core/view_preferences_service.dart';
import '../../../goal_tracker/core/filter_preferences_service.dart';
import '../../../goal_tracker/presentation/widgets/view_field_bottom_sheet.dart';
import '../../../goal_tracker/presentation/widgets/filter_group_bottom_sheet.dart';
import 'itinerary_state.dart';

/// Cubit to manage Itinerary state.
class ItineraryCubit extends Cubit<ItineraryState> {
  final CreateItineraryDay createDay;
  final GetDaysByTripId getDays;
  final UpdateItineraryDay updateDay;
  final DeleteItineraryDay deleteDay;
  final CreateItineraryItem createItem;
  final GetItemsByDayId getItems;
  final UpdateItineraryItem updateItem;
  final DeleteItineraryItem deleteItem;
  final GetTripById getTripById;
  final ViewPreferencesService viewPreferencesService;
  final FilterPreferencesService filterPreferencesService;

  static const _uuid = Uuid();

  // Filter state
  String? _currentDateFilter;
  String? _currentItemTypeFilter;
  String? _currentTripId; // Store current trip ID for filter operations

  // View state
  String _viewType = 'list';
  Map<String, bool> _visibleFields = const {
    'date': true,
    'notes': false,
    'itemType': true,
    'itemTime': true,
    'itemLocation': false,
  };

  String get viewType => _viewType;
  Map<String, bool> get visibleFields => Map<String, bool>.unmodifiable(_visibleFields);
  bool get hasActiveFilters => _currentDateFilter != null || _currentItemTypeFilter != null;
  String get filterSummary {
    final parts = <String>[];
    if (_currentDateFilter != null) parts.add('Date: $_currentDateFilter');
    if (_currentItemTypeFilter != null) parts.add('Type: $_currentItemTypeFilter');
    return parts.isEmpty ? 'No filters' : parts.join(', ');
  }

  ItineraryCubit({
    required this.createDay,
    required this.getDays,
    required this.updateDay,
    required this.deleteDay,
    required this.createItem,
    required this.getItems,
    required this.updateItem,
    required this.deleteItem,
    required this.getTripById,
    required this.viewPreferencesService,
    required this.filterPreferencesService,
  }) : super(ItineraryLoading()) {
    // Load saved preferences
    final savedPrefs = viewPreferencesService.loadViewPreferences(ViewEntityType.itinerary);
    if (savedPrefs != null) {
      _visibleFields = Map<String, bool>.from(savedPrefs);
    }
    final savedViewType = viewPreferencesService.loadViewType(ViewEntityType.itinerary);
    if (savedViewType != null) {
      _viewType = savedViewType;
    }
    final savedFilters = filterPreferencesService.loadFilterPreferences(FilterEntityType.itinerary);
    if (savedFilters != null) {
      _currentDateFilter = savedFilters['targetDate'];
      _currentItemTypeFilter = savedFilters['itemType'];
    }
  }

  Future<void> loadItinerary(String tripId) async {
    try {
      _currentTripId = tripId;
      emit(ItineraryLoading());
      
      // Get trip to check start and end dates
      final trip = await getTripById(tripId);
      
      // Reset days based on start and end dates
      if (trip != null && trip.startDate != null && trip.endDate != null) {
        await _resetDaysForDateRange(tripId, trip.startDate!, trip.endDate!);
      }
      
      final days = await getDays(tripId);
      days.sort((a, b) => a.date.compareTo(b.date));

      final itemsByDay = <String, List<ItineraryItem>>{};
      for (final day in days) {
        final items = await getItems(day.id);
        items.sort((a, b) {
          if (a.time != null && b.time != null) {
            return a.time!.compareTo(b.time!);
          }
          if (a.time != null) return -1;
          if (b.time != null) return 1;
          return a.title.compareTo(b.title);
        });
        itemsByDay[day.id] = items;
      }

      // Apply filters if any are active
      final filteredDays = _applyFilters(days, itemsByDay);
      
      emit(ItineraryLoaded(
        filteredDays.days,
        filteredDays.itemsByDay,
        viewType: _viewType,
        visibleFields: _visibleFields,
      ));
    } catch (e) {
      emit(ItineraryError(e.toString()));
    }
  }

  /// Resets itinerary days based on the new date range.
  /// - Deletes days outside the date range (along with their activities)
  /// - Creates missing days within the date range
  /// - Preserves days and activities within the range
  Future<void> _resetDaysForDateRange(
    String tripId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final existingDays = await getDays(tripId);
    
    // Normalize dates to date-only (remove time component) for comparison
    final startDateNormalized = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateNormalized = DateTime(endDate.year, endDate.month, endDate.day);
    
    // Track which dates should exist in the new range
    final datesInRange = <DateTime>{};
    DateTime currentDate = startDateNormalized;
    while (currentDate.isBefore(endDateNormalized) || currentDate.isAtSameMomentAs(endDateNormalized)) {
      datesInRange.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    // Delete days outside the date range (along with their activities)
    for (final day in existingDays) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      if (!datesInRange.contains(dayDate)) {
        // Delete all items for this day first
        final items = await getItems(day.id);
        for (final item in items) {
          await deleteItem(item.id);
        }
        // Then delete the day
        await deleteDay(day.id);
      }
    }
    
    // Create missing days within the date range
    final remainingDays = await getDays(tripId);
    final existingDates = remainingDays.map((day) {
      final date = day.date;
      return DateTime(date.year, date.month, date.day);
    }).toSet();

    final now = DateTime.now();
    currentDate = startDateNormalized;
    
    while (currentDate.isBefore(endDateNormalized) || currentDate.isAtSameMomentAs(endDateNormalized)) {
      if (!existingDates.contains(currentDate)) {
        final day = ItineraryDay(
          id: _uuid.v4(),
          tripId: tripId,
          date: currentDate,
          notes: null,
          createdAt: now,
          updatedAt: now,
        );
        await createDay(day);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  Future<void> createDayForTrip({
    required String tripId,
    required DateTime date,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final day = ItineraryDay(
        id: _uuid.v4(),
        tripId: tripId,
        date: date,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      await createDay(day);
      await loadItinerary(tripId);
    } catch (e) {
      emit(ItineraryError(e.toString()));
    }
  }

  Future<void> updateDayEntry(ItineraryDay day) async {
    try {
      final updated = ItineraryDay(
        id: day.id,
        tripId: day.tripId,
        date: day.date,
        notes: day.notes,
        createdAt: day.createdAt,
        updatedAt: DateTime.now(),
      );

      await updateDay(updated);
      await loadItinerary(day.tripId);
    } catch (e) {
      emit(ItineraryError(e.toString()));
    }
  }

  Future<void> deleteDayById(String dayId, String tripId) async {
    try {
      await deleteDay(dayId);
      await loadItinerary(tripId);
    } catch (e) {
      emit(ItineraryError(e.toString()));
    }
  }

  Future<void> createItemForDay({
    required String dayId,
    required ItineraryItemType type,
    required String title,
    DateTime? time,
    String? location,
    String? notes,
    String? mapLink,
    required String tripId,
  }) async {
    try {
      final now = DateTime.now();
      final item = ItineraryItem(
        id: _uuid.v4(),
        dayId: dayId,
        type: type,
        title: title,
        time: time,
        location: location,
        notes: notes,
        mapLink: mapLink,
        createdAt: now,
        updatedAt: now,
      );

      await createItem(item);
      await loadItinerary(tripId);
    } catch (e) {
      emit(ItineraryError(e.toString()));
    }
  }

  Future<void> updateItemEntry(ItineraryItem item, String tripId) async {
    try {
      final updated = ItineraryItem(
        id: item.id,
        dayId: item.dayId,
        type: item.type,
        title: item.title,
        time: item.time,
        location: item.location,
        notes: item.notes,
        mapLink: item.mapLink,
        createdAt: item.createdAt,
        updatedAt: DateTime.now(),
      );

      await updateItem(updated);
      await loadItinerary(tripId);
    } catch (e) {
      emit(ItineraryError(e.toString()));
    }
  }

  Future<void> deleteItemById(String itemId, String tripId) async {
    try {
      await deleteItem(itemId);
      await loadItinerary(tripId);
    } catch (e) {
      emit(ItineraryError(e.toString()));
    }
  }

  void setViewType(String viewType) {
    _viewType = viewType;
    if (state is ItineraryLoaded) {
      final current = state as ItineraryLoaded;
      emit(ItineraryLoaded(
        current.days,
        current.itemsByDay,
        viewType: _viewType,
        visibleFields: _visibleFields,
      ));
    }
  }

  void setVisibleFields(Map<String, bool> fields) {
    _visibleFields = Map<String, bool>.from(fields);
    if (state is ItineraryLoaded) {
      final current = state as ItineraryLoaded;
      emit(ItineraryLoaded(
        current.days,
        current.itemsByDay,
        viewType: _viewType,
        visibleFields: _visibleFields,
      ));
    }
  }

  void applyFilter({
    String? targetDate,
    String? itemType,
  }) {
    _currentDateFilter = targetDate;
    _currentItemTypeFilter = itemType;
    if (_currentTripId != null) {
      loadItinerary(_currentTripId!);
    }
  }

  void clearFilters() {
    _currentDateFilter = null;
    _currentItemTypeFilter = null;
    if (_currentTripId != null) {
      loadItinerary(_currentTripId!);
    }
  }

  /// Apply filters to days and items
  ({List<ItineraryDay> days, Map<String, List<ItineraryItem>> itemsByDay}) _applyFilters(
    List<ItineraryDay> days,
    Map<String, List<ItineraryItem>> itemsByDay,
  ) {
    var filteredDays = List<ItineraryDay>.from(days);
    var filteredItemsByDay = Map<String, List<ItineraryItem>>.from(itemsByDay);

    // Apply date filter
    if (_currentDateFilter != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      filteredDays = filteredDays.where((day) {
        final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
        switch (_currentDateFilter) {
          case 'Today':
            return dayDate.isAtSameMomentAs(today);
          case 'Tomorrow':
            return dayDate.isAtSameMomentAs(today.add(const Duration(days: 1)));
          case 'This Week':
            final weekStart = today.subtract(Duration(days: today.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6));
            return dayDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                dayDate.isBefore(weekEnd.add(const Duration(days: 1)));
          case 'Next Week':
            final nextWeekStart = today.add(Duration(days: 8 - today.weekday));
            final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
            return dayDate.isAfter(nextWeekStart.subtract(const Duration(days: 1))) &&
                dayDate.isBefore(nextWeekEnd.add(const Duration(days: 1)));
          case 'This Month':
            return dayDate.year == today.year && dayDate.month == today.month;
          case 'Next Month':
            final nextMonth = DateTime(today.year, today.month + 1, 1);
            return dayDate.year == nextMonth.year && dayDate.month == nextMonth.month;
          case 'This Year':
            return dayDate.year == today.year;
          case 'Next Year':
            return dayDate.year == today.year + 1;
          default:
            return true;
        }
      }).toList();
    }

    // Apply item type filter
    if (_currentItemTypeFilter != null) {
      final itemType = ItineraryItemType.values.firstWhere(
        (type) => type.name == _currentItemTypeFilter,
        orElse: () => ItineraryItemType.sightseeing,
      );
      filteredItemsByDay = Map.fromEntries(
        filteredItemsByDay.entries.map((entry) {
          final filteredItems = entry.value.where((item) => item.type == itemType).toList();
          return MapEntry(entry.key, filteredItems);
        }).where((entry) => entry.value.isNotEmpty),
      );
      // Also filter days to only include those with matching items
      filteredDays = filteredDays.where((day) => filteredItemsByDay.containsKey(day.id)).toList();
    }

    return (days: filteredDays, itemsByDay: filteredItemsByDay);
  }
}

