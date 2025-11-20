import '../../domain/entities/itinerary_day.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../datasources/itinerary_local_data_source.dart';
import '../models/itinerary_day_model.dart';
import '../models/itinerary_item_model.dart';

/// Concrete implementation of ItineraryRepository.
class ItineraryRepositoryImpl implements ItineraryRepository {
  final ItineraryLocalDataSource local;

  ItineraryRepositoryImpl(this.local);

  @override
  Future<void> createDay(ItineraryDay day) async {
    final model = ItineraryDayModel.fromEntity(day);
    await local.createDay(model);
  }

  @override
  Future<void> deleteDay(String id) async {
    await local.deleteDay(id);
  }

  @override
  Future<ItineraryDay?> getDayById(String id) async {
    final model = await local.getDayById(id);
    return model?.toEntity();
  }

  @override
  Future<List<ItineraryDay>> getDaysByTripId(String tripId) async {
    final models = await local.getDaysByTripId(tripId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updateDay(ItineraryDay day) async {
    final model = ItineraryDayModel.fromEntity(day);
    await local.updateDay(model);
  }

  @override
  Future<void> createItem(ItineraryItem item) async {
    final model = ItineraryItemModel.fromEntity(item);
    await local.createItem(model);
  }

  @override
  Future<void> deleteItem(String id) async {
    await local.deleteItem(id);
  }

  @override
  Future<ItineraryItem?> getItemById(String id) async {
    final model = await local.getItemById(id);
    return model?.toEntity();
  }

  @override
  Future<List<ItineraryItem>> getItemsByDayId(String dayId) async {
    final models = await local.getItemsByDayId(dayId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updateItem(ItineraryItem item) async {
    final model = ItineraryItemModel.fromEntity(item);
    await local.updateItem(model);
  }
}

