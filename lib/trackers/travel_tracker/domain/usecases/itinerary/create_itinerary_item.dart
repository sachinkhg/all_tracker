import '../../entities/itinerary_item.dart';
import '../../repositories/itinerary_repository.dart';

/// Use case for creating an itinerary item.
class CreateItineraryItem {
  final ItineraryRepository repository;

  CreateItineraryItem(this.repository);

  Future<void> call(ItineraryItem item) async => repository.createItem(item);
}

