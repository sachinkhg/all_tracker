import '../../entities/trip_profile.dart';
import '../../repositories/trip_profile_repository.dart';

/// Use case for updating a trip profile.
class UpdateProfile {
  final TripProfileRepository repository;

  UpdateProfile(this.repository);

  Future<void> call(TripProfile profile) async => repository.updateProfile(profile);
}

