import '../../domain/entities/traveler.dart';
import '../../domain/repositories/traveler_repository.dart';
import '../datasources/traveler_local_data_source.dart';
import '../models/traveler_model.dart';

/// Concrete implementation of TravelerRepository.
class TravelerRepositoryImpl implements TravelerRepository {
  final TravelerLocalDataSource local;

  TravelerRepositoryImpl(this.local);

  @override
  Future<void> createTraveler(Traveler traveler) async {
    final model = TravelerModel.fromEntity(traveler);
    await local.createTraveler(model);
  }

  @override
  Future<void> deleteTraveler(String id) async {
    await local.deleteTraveler(id);
  }

  @override
  Future<Traveler?> getTravelerById(String id) async {
    final model = await local.getTravelerById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Traveler>> getTravelersByTripId(String tripId) async {
    final models = await local.getTravelersByTripId(tripId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updateTraveler(Traveler traveler) async {
    final model = TravelerModel.fromEntity(traveler);
    await local.updateTraveler(model);
  }
}

