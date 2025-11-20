import 'package:hive/hive.dart';
import '../models/itinerary_day_model.dart';
import '../models/itinerary_item_model.dart';

/// Abstract data source for local itinerary storage.
abstract class ItineraryLocalDataSource {
  // Day operations
  Future<List<ItineraryDayModel>> getDaysByTripId(String tripId);
  Future<ItineraryDayModel?> getDayById(String id);
  Future<void> createDay(ItineraryDayModel day);
  Future<void> updateDay(ItineraryDayModel day);
  Future<void> deleteDay(String id);

  // Item operations
  Future<List<ItineraryItemModel>> getItemsByDayId(String dayId);
  Future<ItineraryItemModel?> getItemById(String id);
  Future<void> createItem(ItineraryItemModel item);
  Future<void> updateItem(ItineraryItemModel item);
  Future<void> deleteItem(String id);
}

/// Hive implementation of ItineraryLocalDataSource.
class ItineraryLocalDataSourceImpl implements ItineraryLocalDataSource {
  final Box<ItineraryDayModel> dayBox;
  final Box<ItineraryItemModel> itemBox;

  ItineraryLocalDataSourceImpl({
    required this.dayBox,
    required this.itemBox,
  });

  @override
  Future<void> createDay(ItineraryDayModel day) async {
    await dayBox.put(day.id, day);
  }

  @override
  Future<void> deleteDay(String id) async {
    await dayBox.delete(id);
  }

  @override
  Future<ItineraryDayModel?> getDayById(String id) async {
    return dayBox.get(id);
  }

  @override
  Future<List<ItineraryDayModel>> getDaysByTripId(String tripId) async {
    return dayBox.values.where((day) => day.tripId == tripId).toList();
  }

  @override
  Future<void> updateDay(ItineraryDayModel day) async {
    await dayBox.put(day.id, day);
  }

  @override
  Future<void> createItem(ItineraryItemModel item) async {
    await itemBox.put(item.id, item);
  }

  @override
  Future<void> deleteItem(String id) async {
    await itemBox.delete(id);
  }

  @override
  Future<ItineraryItemModel?> getItemById(String id) async {
    return itemBox.get(id);
  }

  @override
  Future<List<ItineraryItemModel>> getItemsByDayId(String dayId) async {
    return itemBox.values.where((item) => item.dayId == dayId).toList();
  }

  @override
  Future<void> updateItem(ItineraryItemModel item) async {
    await itemBox.put(item.id, item);
  }
}

