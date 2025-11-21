import '../../entities/traveler.dart';
import '../../repositories/traveler_repository.dart';

/// Use case for updating a traveler.
class UpdateTraveler {
  final TravelerRepository repository;

  UpdateTraveler(this.repository);

  Future<void> call(Traveler traveler) async => repository.updateTraveler(traveler);
}

