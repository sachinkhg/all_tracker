import '../../repositories/itinerary_repository.dart';

/// Use case for deleting an itinerary day.
class DeleteItineraryDay {
  final ItineraryRepository repository;

  DeleteItineraryDay(this.repository);

  Future<void> call(String id) async => repository.deleteDay(id);
}

