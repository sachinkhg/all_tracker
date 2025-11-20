import '../../entities/itinerary_day.dart';
import '../../repositories/itinerary_repository.dart';

/// Use case for updating an itinerary day.
class UpdateItineraryDay {
  final ItineraryRepository repository;

  UpdateItineraryDay(this.repository);

  Future<void> call(ItineraryDay day) async => repository.updateDay(day);
}

