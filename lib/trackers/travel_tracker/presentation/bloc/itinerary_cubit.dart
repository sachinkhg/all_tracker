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

  static const _uuid = Uuid();

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
  }) : super(ItineraryLoading());

  Future<void> loadItinerary(String tripId) async {
    try {
      emit(ItineraryLoading());
      
      // Get trip to check start and end dates
      final trip = await getTripById(tripId);
      
      // Auto-generate days if trip has start and end dates
      if (trip != null && trip.startDate != null && trip.endDate != null) {
        await _ensureDaysExist(tripId, trip.startDate!, trip.endDate!);
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

      emit(ItineraryLoaded(days, itemsByDay));
    } catch (e) {
      emit(ItineraryError(e.toString()));
    }
  }

  /// Ensures that itinerary days exist for all dates between startDate and endDate.
  /// Only creates days that don't already exist.
  Future<void> _ensureDaysExist(
    String tripId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final existingDays = await getDays(tripId);
    final existingDates = existingDays.map((day) {
      // Normalize to date only (remove time component)
      final date = day.date;
      return DateTime(date.year, date.month, date.day);
    }).toSet();

    final now = DateTime.now();
    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateNormalized = DateTime(endDate.year, endDate.month, endDate.day);

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
}

