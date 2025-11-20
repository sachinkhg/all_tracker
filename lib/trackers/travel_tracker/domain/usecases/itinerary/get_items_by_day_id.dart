import '../../entities/itinerary_item.dart';
import '../../repositories/itinerary_repository.dart';

/// Use case for retrieving all items for a day.
class GetItemsByDayId {
  final ItineraryRepository repository;

  GetItemsByDayId(this.repository);

  Future<List<ItineraryItem>> call(String dayId) async => repository.getItemsByDayId(dayId);
}

