import '../entities/itinerary_day.dart';
import '../entities/itinerary_item.dart';

/// Abstract repository defining operations for itinerary entities.
abstract class ItineraryRepository {
  // ItineraryDay operations
  /// Get all days for a trip.
  Future<List<ItineraryDay>> getDaysByTripId(String tripId);

  /// Get a day by ID.
  Future<ItineraryDay?> getDayById(String id);

  /// Create a new itinerary day.
  Future<void> createDay(ItineraryDay day);

  /// Update an itinerary day.
  Future<void> updateDay(ItineraryDay day);

  /// Delete an itinerary day.
  Future<void> deleteDay(String id);

  // ItineraryItem operations
  /// Get all items for a day.
  Future<List<ItineraryItem>> getItemsByDayId(String dayId);

  /// Get an item by ID.
  Future<ItineraryItem?> getItemById(String id);

  /// Create a new itinerary item.
  Future<void> createItem(ItineraryItem item);

  /// Update an itinerary item.
  Future<void> updateItem(ItineraryItem item);

  /// Delete an itinerary item.
  Future<void> deleteItem(String id);
}

