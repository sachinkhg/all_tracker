import '../../entities/traveler.dart';
import '../../repositories/traveler_repository.dart';

/// Use case for retrieving a traveler by ID.
class GetTravelerById {
  final TravelerRepository repository;

  GetTravelerById(this.repository);

  Future<Traveler?> call(String id) async => repository.getTravelerById(id);
}

