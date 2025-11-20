import '../../domain/entities/trip_profile.dart';
import '../../domain/repositories/trip_profile_repository.dart';
import '../datasources/trip_profile_local_data_source.dart';
import '../models/trip_profile_model.dart';

/// Concrete implementation of TripProfileRepository.
class TripProfileRepositoryImpl implements TripProfileRepository {
  final TripProfileLocalDataSource local;

  TripProfileRepositoryImpl(this.local);

  @override
  Future<void> createProfile(TripProfile profile) async {
    final model = TripProfileModel.fromEntity(profile);
    await local.createProfile(model);
  }

  @override
  Future<void> deleteProfileByTripId(String tripId) async {
    await local.deleteProfileByTripId(tripId);
  }

  @override
  Future<TripProfile?> getProfileByTripId(String tripId) async {
    final model = await local.getProfileByTripId(tripId);
    return model?.toEntity();
  }

  @override
  Future<void> updateProfile(TripProfile profile) async {
    final model = TripProfileModel.fromEntity(profile);
    await local.updateProfile(model);
  }
}

