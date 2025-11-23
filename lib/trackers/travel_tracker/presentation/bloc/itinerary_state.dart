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
  final String viewType; // 'list' or 'calendar'
  final Map<String, bool>? visibleFields; // Field visibility preferences

  const ItineraryLoaded(
    this.days,
    this.itemsByDay, {
    this.viewType = 'list',
    this.visibleFields,
  });

  @override
  List<Object?> get props => [days, itemsByDay, viewType, visibleFields];
}

/// Error state.
class ItineraryError extends ItineraryState {
  final String message;

  const ItineraryError(this.message);

  @override
  List<Object?> get props => [message];
}

