import '../../entities/itinerary_day.dart';
import '../../repositories/itinerary_repository.dart';

/// Use case for creating an itinerary day.
class CreateItineraryDay {
  final ItineraryRepository repository;

  CreateItineraryDay(this.repository);

  Future<void> call(ItineraryDay day) async => repository.createDay(day);
}

