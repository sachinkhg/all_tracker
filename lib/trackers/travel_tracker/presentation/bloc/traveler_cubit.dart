import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/traveler.dart';
import '../../domain/usecases/traveler/create_traveler.dart';
import '../../domain/usecases/traveler/get_travelers_by_trip_id.dart';
import '../../domain/usecases/traveler/update_traveler.dart';
import '../../domain/usecases/traveler/delete_traveler.dart';
import 'traveler_state.dart';

/// Cubit to manage Traveler state.
class TravelerCubit extends Cubit<TravelerState> {
  final CreateTraveler create;
  final GetTravelersByTripId getTravelers;
  final UpdateTraveler update;
  final DeleteTraveler delete;

  static const _uuid = Uuid();

  TravelerCubit({
    required this.create,
    required this.getTravelers,
    required this.update,
    required this.delete,
  }) : super(TravelersLoading());

  Future<void> loadTravelers(String tripId) async {
    try {
      emit(TravelersLoading());
      final travelers = await getTravelers(tripId);
      // Sort: main traveler first, then by name
      travelers.sort((a, b) {
        if (a.isMainTraveler && !b.isMainTraveler) return -1;
        if (!a.isMainTraveler && b.isMainTraveler) return 1;
        return a.name.compareTo(b.name);
      });
      emit(TravelersLoaded(travelers));
    } catch (e) {
      emit(TravelersError(e.toString()));
    }
  }

  Future<void> createTraveler({
    required String tripId,
    required String name,
    String? relationship,
    String? email,
    String? phone,
    String? notes,
    bool isMainTraveler = false,
  }) async {
    try {
      final now = DateTime.now();
      final traveler = Traveler(
        id: _uuid.v4(),
        tripId: tripId,
        name: name,
        relationship: relationship,
        email: email,
        phone: phone,
        notes: notes,
        isMainTraveler: isMainTraveler,
        createdAt: now,
        updatedAt: now,
      );

      await create(traveler);
      await loadTravelers(tripId);
    } catch (e) {
      emit(TravelersError(e.toString()));
    }
  }

  Future<void> updateTraveler(Traveler traveler) async {
    try {
      final updated = Traveler(
        id: traveler.id,
        tripId: traveler.tripId,
        name: traveler.name,
        relationship: traveler.relationship,
        email: traveler.email,
        phone: traveler.phone,
        notes: traveler.notes,
        isMainTraveler: traveler.isMainTraveler,
        createdAt: traveler.createdAt,
        updatedAt: DateTime.now(),
      );

      await update(updated);
      await loadTravelers(traveler.tripId);
    } catch (e) {
      emit(TravelersError(e.toString()));
    }
  }

  Future<void> deleteTraveler(String id, String tripId) async {
    try {
      await delete(id);
      await loadTravelers(tripId);
    } catch (e) {
      emit(TravelersError(e.toString()));
    }
  }
}

