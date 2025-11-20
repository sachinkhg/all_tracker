import '../../repositories/itinerary_repository.dart';

/// Use case for deleting an itinerary item.
class DeleteItineraryItem {
  final ItineraryRepository repository;

  DeleteItineraryItem(this.repository);

  Future<void> call(String id) async => repository.deleteItem(id);
}

