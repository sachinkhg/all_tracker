import 'package:equatable/equatable.dart';
import '../../domain/entities/traveler.dart';

/// Base state for traveler operations.
abstract class TravelerState extends Equatable {
  const TravelerState();

  @override
  List<Object?> get props => [];
}

/// Loading state.
class TravelersLoading extends TravelerState {}

/// Loaded state with travelers.
class TravelersLoaded extends TravelerState {
  final List<Traveler> travelers;

  const TravelersLoaded(this.travelers);

  @override
  List<Object?> get props => [travelers];
}

/// Error state.
class TravelersError extends TravelerState {
  final String message;

  const TravelersError(this.message);

  @override
  List<Object?> get props => [message];
}

