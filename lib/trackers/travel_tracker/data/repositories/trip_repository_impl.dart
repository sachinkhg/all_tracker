import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_local_data_source.dart';
import '../models/trip_model.dart';

/// Concrete implementation of TripRepository.
class TripRepositoryImpl implements TripRepository {
  final TripLocalDataSource local;

  TripRepositoryImpl(this.local);

  @override
  Future<void> createTrip(Trip trip) async {
    final model = TripModel.fromEntity(trip);
    await local.createTrip(model);
  }

  @override
  Future<void> deleteTrip(String id) async {
    await local.deleteTrip(id);
  }

  @override
  Future<List<Trip>> getAllTrips() async {
    final models = await local.getAllTrips();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Trip?> getTripById(String id) async {
    final model = await local.getTripById(id);
    return model?.toEntity();
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    final model = TripModel.fromEntity(trip);
    await local.updateTrip(model);
  }
}

