import '../../entities/itinerary_item.dart';
import '../../repositories/itinerary_repository.dart';

/// Use case for updating an itinerary item.
class UpdateItineraryItem {
  final ItineraryRepository repository;

  UpdateItineraryItem(this.repository);

  Future<void> call(ItineraryItem item) async => repository.updateItem(item);
}

