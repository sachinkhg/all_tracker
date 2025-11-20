import '../../entities/trip_profile.dart';
import '../../repositories/trip_profile_repository.dart';

/// Use case for creating a trip profile.
class CreateProfile {
  final TripProfileRepository repository;

  CreateProfile(this.repository);

  Future<void> call(TripProfile profile) async => repository.createProfile(profile);
}

