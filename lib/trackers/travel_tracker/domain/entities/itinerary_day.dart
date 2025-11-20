import 'package:equatable/equatable.dart';

/// Domain model for an Itinerary Day.
///
/// Represents a single day within a trip's itinerary.
/// Each day can have multiple itinerary items (activities).
class ItineraryDay extends Equatable {
  /// Unique identifier for the day (GUID recommended).
  final String id;

  /// Associated trip ID.
  final String tripId;

  /// Date for this itinerary day.
  final DateTime date;

  /// Optional notes for the day.
  final String? notes;

  /// When the day was created.
  final DateTime createdAt;

  /// When the day was last updated.
  final DateTime updatedAt;

  const ItineraryDay({
    required this.id,
    required this.tripId,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        tripId,
        date,
        notes,
        createdAt,
        updatedAt,
      ];
}

