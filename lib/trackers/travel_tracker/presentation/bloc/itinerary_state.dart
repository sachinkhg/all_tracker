import 'package:equatable/equatable.dart';
import '../../domain/entities/itinerary_day.dart';
import '../../domain/entities/itinerary_item.dart';

/// Base state for itinerary operations.
abstract class ItineraryState extends Equatable {
  const ItineraryState();

  @override
  List<Object?> get props => [];
}

/// Loading state.
class ItineraryLoading extends ItineraryState {}

/// Loaded state with days and items.
class ItineraryLoaded extends ItineraryState {
  final List<ItineraryDay> days;
  final Map<String, List<ItineraryItem>> itemsByDay;

  const ItineraryLoaded(this.days, this.itemsByDay);

  @override
  List<Object?> get props => [days, itemsByDay];
}

/// Error state.
class ItineraryError extends ItineraryState {
  final String message;

  const ItineraryError(this.message);

  @override
  List<Object?> get props => [message];
}

