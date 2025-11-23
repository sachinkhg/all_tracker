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
  final String viewType; // 'list' or 'calendar'
  final Map<String, bool>? visibleFields; // Field visibility preferences

  const TripsLoaded(
    this.trips, {
    this.viewType = 'list',
    this.visibleFields,
  });

  @override
  List<Object?> get props => [trips, viewType, visibleFields];
}

/// Error state - emitted when fetching or modifying trips fails.
class TripsError extends TripState {
  final String message;

  const TripsError(this.message);

  @override
  List<Object?> get props => [message];
}

