import '../models/traveler_model.dart';
import 'package:hive/hive.dart';

/// Abstract data source for local traveler storage.
abstract class TravelerLocalDataSource {
  Future<List<TravelerModel>> getTravelersByTripId(String tripId);
  Future<TravelerModel?> getTravelerById(String id);
  Future<void> createTraveler(TravelerModel traveler);
  Future<void> updateTraveler(TravelerModel traveler);
  Future<void> deleteTraveler(String id);
}

/// Hive implementation of TravelerLocalDataSource.
class TravelerLocalDataSourceImpl implements TravelerLocalDataSource {
  final Box<TravelerModel> box;

  TravelerLocalDataSourceImpl(this.box);

  @override
  Future<void> createTraveler(TravelerModel traveler) async {
    await box.put(traveler.id, traveler);
  }

  @override
  Future<void> deleteTraveler(String id) async {
    await box.delete(id);
  }

  @override
  Future<TravelerModel?> getTravelerById(String id) async {
    return box.get(id);
  }

  @override
  Future<List<TravelerModel>> getTravelersByTripId(String tripId) async {
    return box.values.where((traveler) => traveler.tripId == tripId).toList();
  }

  @override
  Future<void> updateTraveler(TravelerModel traveler) async {
    await box.put(traveler.id, traveler);
  }
}

