import 'package:hive/hive.dart';
import '../models/trip_model.dart';

/// Abstract data source for local trip storage.
abstract class TripLocalDataSource {
  Future<List<TripModel>> getAllTrips();
  Future<TripModel?> getTripById(String id);
  Future<void> createTrip(TripModel trip);
  Future<void> updateTrip(TripModel trip);
  Future<void> deleteTrip(String id);
}

/// Hive implementation of TripLocalDataSource.
class TripLocalDataSourceImpl implements TripLocalDataSource {
  final Box<TripModel> box;

  TripLocalDataSourceImpl(this.box);

  @override
  Future<void> createTrip(TripModel trip) async {
    await box.put(trip.id, trip);
  }

  @override
  Future<void> deleteTrip(String id) async {
    await box.delete(id);
  }

  @override
  Future<TripModel?> getTripById(String id) async {
    return box.get(id);
  }

  @override
  Future<List<TripModel>> getAllTrips() async {
    return box.values.toList();
  }

  @override
  Future<void> updateTrip(TripModel trip) async {
    await box.put(trip.id, trip);
  }
}

