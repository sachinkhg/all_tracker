import 'package:equatable/equatable.dart';

/// Domain model for a Traveler.
///
/// Represents a traveler in a trip. Multiple travelers can be associated with a trip.
/// The first traveler added is typically the main traveler (self).
class Traveler extends Equatable {
  /// Unique identifier for the traveler.
  final String id;

  /// Associated trip ID.
  final String tripId;

  /// Traveler's name.
  final String name;

  /// Relationship to the main traveler (e.g., "Self", "Spouse", "Child", "Friend", etc.).
  final String? relationship;

  /// Traveler's email.
  final String? email;

  /// Traveler's phone number.
  final String? phone;

  /// Additional notes about the traveler.
  final String? notes;

  /// Whether this traveler is the main traveler (self).
  final bool isMainTraveler;

  /// When the traveler was created.
  final DateTime createdAt;

  /// When the traveler was last updated.
  final DateTime updatedAt;

  const Traveler({
    required this.id,
    required this.tripId,
    required this.name,
    this.relationship,
    this.email,
    this.phone,
    this.notes,
    this.isMainTraveler = false,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        tripId,
        name,
        relationship,
        email,
        phone,
        notes,
        isMainTraveler,
        createdAt,
        updatedAt,
      ];
}

