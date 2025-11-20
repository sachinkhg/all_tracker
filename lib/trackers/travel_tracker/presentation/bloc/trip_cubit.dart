import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/trip.dart';
import '../../domain/usecases/trip/get_all_trips.dart';
import '../../domain/usecases/trip/create_trip.dart';
import '../../domain/usecases/trip/update_trip.dart';
import '../../domain/usecases/trip/delete_trip.dart';
import '../../domain/usecases/trip/get_trip_by_id.dart';
import 'trip_state.dart';

/// Cubit to manage Trip state.
class TripCubit extends Cubit<TripState> {
  final GetAllTrips getAll;
  final CreateTrip create;
  final UpdateTrip update;
  final DeleteTrip delete;
  final GetTripById getById;

  static const _uuid = Uuid();

  TripCubit({
    required this.getAll,
    required this.create,
    required this.update,
    required this.delete,
    required this.getById,
  }) : super(TripsLoading());

  Future<void> loadTrips() async {
    try {
      emit(TripsLoading());
      final trips = await getAll();
      emit(TripsLoaded(List.from(trips)));
    } catch (e) {
      emit(TripsError(e.toString()));
    }
  }

  Future<void> createNewTrip({
    required String title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  }) async {
    try {
      final now = DateTime.now();
      final trip = Trip(
        id: _uuid.v4(),
        title: title,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      await create(trip);
      await loadTrips();
    } catch (e) {
      emit(TripsError(e.toString()));
    }
  }

  Future<void> updateTrip(Trip trip) async {
    try {
      final updated = Trip(
        id: trip.id,
        title: trip.title,
        destination: trip.destination,
        startDate: trip.startDate,
        endDate: trip.endDate,
        description: trip.description,
        createdAt: trip.createdAt,
        updatedAt: DateTime.now(),
      );

      await update(updated);
      await loadTrips();
    } catch (e) {
      emit(TripsError(e.toString()));
    }
  }

  Future<void> deleteTrip(String id) async {
    try {
      await delete(id);
      await loadTrips();
    } catch (e) {
      emit(TripsError(e.toString()));
    }
  }

  Future<Trip?> getTripById(String id) async {
    try {
      return await getById(id);
    } catch (e) {
      emit(TripsError(e.toString()));
      return null;
    }
  }
}

