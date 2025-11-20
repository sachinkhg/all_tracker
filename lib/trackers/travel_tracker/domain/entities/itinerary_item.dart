import 'package:equatable/equatable.dart';
import '../../core/constants.dart';

/// Domain model for an Itinerary Item (Activity).
///
/// Represents a single activity within an itinerary day.
/// Activities can be travel, stay, meal, or sightseeing.
class ItineraryItem extends Equatable {
  /// Unique identifier for the item (GUID recommended).
  final String id;

  /// Associated itinerary day ID.
  final String dayId;

  /// Type of activity.
  final ItineraryItemType type;

  /// Title/name of the activity.
  final String title;

  /// Time of day for this activity (optional, stored as DateTime but only time component matters).
  final DateTime? time;

  /// Location of the activity.
  final String? location;

  /// Optional notes about the activity.
  final String? notes;

  /// Map link (Google Maps or Apple Maps URL).
  final String? mapLink;

  /// When the item was created.
  final DateTime createdAt;

  /// When the item was last updated.
  final DateTime updatedAt;

  const ItineraryItem({
    required this.id,
    required this.dayId,
    required this.type,
    required this.title,
    this.time,
    this.location,
    this.notes,
    this.mapLink,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        dayId,
        type,
        title,
        time,
        location,
        notes,
        mapLink,
        createdAt,
        updatedAt,
      ];
}

