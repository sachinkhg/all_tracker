import 'package:hive/hive.dart';
import '../models/trip_profile_model.dart';

/// Abstract data source for local trip profile storage.
abstract class TripProfileLocalDataSource {
  Future<TripProfileModel?> getProfileByTripId(String tripId);
  Future<void> createProfile(TripProfileModel profile);
  Future<void> updateProfile(TripProfileModel profile);
  Future<void> deleteProfileByTripId(String tripId);
}

/// Hive implementation of TripProfileLocalDataSource.
class TripProfileLocalDataSourceImpl implements TripProfileLocalDataSource {
  final Box<TripProfileModel> box;

  TripProfileLocalDataSourceImpl(this.box);

  @override
  Future<void> createProfile(TripProfileModel profile) async {
    await box.put(profile.id, profile);
  }

  @override
  Future<void> deleteProfileByTripId(String tripId) async {
    final profile = await getProfileByTripId(tripId);
    if (profile != null) {
      await box.delete(profile.id);
    }
  }

  @override
  Future<TripProfileModel?> getProfileByTripId(String tripId) async {
    for (final profile in box.values) {
      if (profile.tripId == tripId) {
        return profile;
      }
    }
    return null;
  }

  @override
  Future<void> updateProfile(TripProfileModel profile) async {
    await box.put(profile.id, profile);
  }
}

