import '../../entities/traveler.dart';
import '../../repositories/traveler_repository.dart';

/// Use case for creating a new traveler.
class CreateTraveler {
  final TravelerRepository repository;

  CreateTraveler(this.repository);

  Future<void> call(Traveler traveler) async => repository.createTraveler(traveler);
}

