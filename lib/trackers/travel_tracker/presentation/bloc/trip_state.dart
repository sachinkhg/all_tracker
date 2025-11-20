import 'package:equatable/equatable.dart';
import '../../domain/entities/trip.dart';

/// Base state for trip operations.
abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

/// Loading state - emitted when trip data is being fetched.
class TripsLoading extends TripState {}

/// Loaded state - holds the list of successfully fetched trips.
class TripsLoaded extends TripState {
  final List<Trip> trips;

  const TripsLoaded(this.trips);

  @override
  List<Object?> get props => [trips];
}

/// Error state - emitted when fetching or modifying trips fails.
class TripsError extends TripState {
  final String message;

  const TripsError(this.message);

  @override
  List<Object?> get props => [message];
}

