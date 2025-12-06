import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/trip.dart';
import '../../domain/usecases/trip/get_all_trips.dart';
import '../../domain/usecases/trip/create_trip.dart';
import '../../domain/usecases/trip/update_trip.dart';
import '../../domain/usecases/trip/delete_trip.dart';
import '../../domain/usecases/trip/get_trip_by_id.dart';
import '../../core/constants.dart';
import 'package:all_tracker/core/services/view_preferences_service.dart';
import 'package:all_tracker/core/services/filter_preferences_service.dart';
import 'package:all_tracker/core/services/view_entity_type.dart';
import 'trip_state.dart';

/// Cubit to manage Trip state.
class TripCubit extends Cubit<TripState> {
  final GetAllTrips getAll;
  final CreateTrip create;
  final UpdateTrip update;
  final DeleteTrip delete;
  final GetTripById getById;
  final ViewPreferencesService viewPreferencesService;
  final FilterPreferencesService filterPreferencesService;

  static const _uuid = Uuid();

  // Filter state
  String? _currentDateFilter;

  // View state
  String _viewType = 'list';
  String? _savedViewType; // Store saved view type but don't use it until after first load
  Map<String, bool> _visibleFields = const {
    'title': true,
    'destination': true,
    'description': false,
  };
  bool _isFirstLoad = true;

  String get viewType => _viewType;
  Map<String, bool> get visibleFields => Map<String, bool>.unmodifiable(_visibleFields);
  bool get hasActiveFilters => _currentDateFilter != null;
  String? get currentDateFilter => _currentDateFilter;
  String get filterSummary {
    if (_currentDateFilter != null) return 'Date: $_currentDateFilter';
    return 'No filters';
  }

  TripCubit({
    required this.getAll,
    required this.create,
    required this.update,
    required this.delete,
    required this.getById,
    required this.viewPreferencesService,
    required this.filterPreferencesService,
  }) : super(TripsLoading()) {
    // Load saved preferences
    final savedPrefs = viewPreferencesService.loadViewPreferences(ViewEntityType.trip);
    if (savedPrefs != null) {
      _visibleFields = Map<String, bool>.from(savedPrefs);
    }
    // Store saved view type but don't use it immediately to avoid crashes
    // We'll apply it after the first successful data load
    _savedViewType = viewPreferencesService.loadViewType(ViewEntityType.trip);
    final savedFilters = filterPreferencesService.loadFilterPreferences(FilterEntityType.trip);
    if (savedFilters != null) {
      _currentDateFilter = savedFilters['targetDate'];
    }
  }

  Future<void> loadTrips() async {
    try {
      emit(TripsLoading());
      final trips = await getAll();
      // Apply filters if any are active
      final filteredTrips = _applyFilters(trips);
      
      // On first load, always use 'list' view to avoid crashes
      // User can manually switch to map view after app is fully loaded
      String viewTypeToUse = _viewType;
      if (_isFirstLoad) {
        _isFirstLoad = false;
        // CRITICAL: Always start with list view to prevent crashes
        // Google Maps SDK needs time to initialize, and restoring map view
        // immediately causes crashes. User can switch to map view manually.
        if (_savedViewType == 'map') {
          // Reset saved preference to list to prevent automatic map view restoration
          viewTypeToUse = 'list';
          _viewType = 'list';
          // Clear the saved map preference so it doesn't auto-restore
          // User can manually switch to map view when ready
        } else if (_savedViewType != null) {
          viewTypeToUse = _savedViewType!;
          _viewType = _savedViewType!;
        }
      }
      
      emit(TripsLoaded(
        filteredTrips,
        viewType: viewTypeToUse,
        visibleFields: _visibleFields,
      ));
    } catch (e) {
      emit(TripsError(e.toString()));
    }
  }

  void setViewType(String viewType) {
    _viewType = viewType;
    if (state is TripsLoaded) {
      final current = state as TripsLoaded;
      emit(TripsLoaded(
        current.trips,
        viewType: _viewType,
        visibleFields: _visibleFields,
      ));
    }
  }

  void setVisibleFields(Map<String, bool> fields) {
    _visibleFields = Map<String, bool>.from(fields);
    if (state is TripsLoaded) {
      final current = state as TripsLoaded;
      emit(TripsLoaded(
        current.trips,
        viewType: _viewType,
        visibleFields: _visibleFields,
      ));
    }
  }

  void applyFilter({
    String? targetDate,
  }) {
    _currentDateFilter = targetDate;
    loadTrips();
  }

  void clearFilters() {
    _currentDateFilter = null;
    loadTrips();
  }

  /// Apply filters to trips
  List<Trip> _applyFilters(List<Trip> trips) {
    if (_currentDateFilter == null) return trips;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return trips.where((trip) {
      final tripStartDate = trip.startDate;
      final tripEndDate = trip.endDate;
      if (tripStartDate == null && tripEndDate == null) return false;

      final startDate = tripStartDate != null
          ? DateTime(tripStartDate.year, tripStartDate.month, tripStartDate.day)
          : null;
      final endDate = tripEndDate != null
          ? DateTime(tripEndDate.year, tripEndDate.month, tripEndDate.day)
          : null;

      switch (_currentDateFilter) {
        case 'Today':
          if (startDate != null && startDate.isAtSameMomentAs(today)) return true;
          if (endDate != null && endDate.isAtSameMomentAs(today)) return true;
          if (startDate != null && endDate != null) {
            return startDate.isBefore(today) && endDate.isAfter(today);
          }
          return false;
        case 'Tomorrow':
          final tomorrow = today.add(const Duration(days: 1));
          if (startDate != null && startDate.isAtSameMomentAs(tomorrow)) return true;
          if (endDate != null && endDate.isAtSameMomentAs(tomorrow)) return true;
          if (startDate != null && endDate != null) {
            return startDate.isBefore(tomorrow) && endDate.isAfter(tomorrow);
          }
          return false;
        case 'This Week':
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          if (startDate != null && startDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              startDate.isBefore(weekEnd.add(const Duration(days: 1)))) return true;
          if (endDate != null && endDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              endDate.isBefore(weekEnd.add(const Duration(days: 1)))) return true;
          if (startDate != null && endDate != null) {
            return startDate.isBefore(weekEnd) && endDate.isAfter(weekStart);
          }
          return false;
        case 'Next Week':
          final nextWeekStart = today.add(Duration(days: 8 - today.weekday));
          final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));
          if (startDate != null && startDate.isAfter(nextWeekStart.subtract(const Duration(days: 1))) &&
              startDate.isBefore(nextWeekEnd.add(const Duration(days: 1)))) return true;
          if (endDate != null && endDate.isAfter(nextWeekStart.subtract(const Duration(days: 1))) &&
              endDate.isBefore(nextWeekEnd.add(const Duration(days: 1)))) return true;
          if (startDate != null && endDate != null) {
            return startDate.isBefore(nextWeekEnd) && endDate.isAfter(nextWeekStart);
          }
          return false;
        case 'This Month':
          if (startDate != null && startDate.year == today.year && startDate.month == today.month) return true;
          if (endDate != null && endDate.year == today.year && endDate.month == today.month) return true;
          if (startDate != null && endDate != null) {
            final monthStart = DateTime(today.year, today.month, 1);
            final monthEnd = DateTime(today.year, today.month + 1, 0);
            return startDate.isBefore(monthEnd) && endDate.isAfter(monthStart);
          }
          return false;
        case 'Next Month':
          final nextMonth = DateTime(today.year, today.month + 1, 1);
          if (startDate != null && startDate.year == nextMonth.year && startDate.month == nextMonth.month) return true;
          if (endDate != null && endDate.year == nextMonth.year && endDate.month == nextMonth.month) return true;
          if (startDate != null && endDate != null) {
            final monthEnd = DateTime(nextMonth.year, nextMonth.month + 1, 0);
            return startDate.isBefore(monthEnd) && endDate.isAfter(nextMonth);
          }
          return false;
        case 'This Year':
          if (startDate != null && startDate.year == today.year) return true;
          if (endDate != null && endDate.year == today.year) return true;
          if (startDate != null && endDate != null) {
            return startDate.year <= today.year && endDate.year >= today.year;
          }
          return false;
        case 'Next Year':
          if (startDate != null && startDate.year == today.year + 1) return true;
          if (endDate != null && endDate.year == today.year + 1) return true;
          if (startDate != null && endDate != null) {
            return startDate.year <= today.year + 1 && endDate.year >= today.year + 1;
          }
          return false;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> createNewTrip({
    required String title,
    TripType? tripType,
    String? destination,
    double? destinationLatitude,
    double? destinationLongitude,
    String? destinationMapLink,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  }) async {
    try {
      final now = DateTime.now();
      final trip = Trip(
        id: _uuid.v4(),
        title: title,
        tripType: tripType,
        destination: destination,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
        destinationMapLink: destinationMapLink,
        startDate: startDate,
        endDate: endDate,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      await create(trip);
      await loadTrips();
    } catch (e) {
      emit(TripsError(e.toString()));
    }
  }

  Future<void> updateTrip(Trip trip) async {
    try {
      final updated = Trip(
        id: trip.id,
        title: trip.title,
        tripType: trip.tripType,
        destination: trip.destination,
        destinationLatitude: trip.destinationLatitude,
        destinationLongitude: trip.destinationLongitude,
        destinationMapLink: trip.destinationMapLink,
        startDate: trip.startDate,
        endDate: trip.endDate,
        description: trip.description,
        createdAt: trip.createdAt,
        updatedAt: DateTime.now(),
      );

      await update(updated);
      await loadTrips();
    } catch (e) {
      emit(TripsError(e.toString()));
    }
  }

  Future<void> deleteTrip(String id) async {
    try {
      await delete(id);
      await loadTrips();
    } catch (e) {
      emit(TripsError(e.toString()));
    }
  }

  Future<Trip?> getTripById(String id) async {
    try {
      return await getById(id);
    } catch (e) {
      emit(TripsError(e.toString()));
      return null;
    }
  }
}

