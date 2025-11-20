import 'package:equatable/equatable.dart';

/// Domain model for Trip Profile.
///
/// Represents basic profile information for a trip (traveler details).
/// One profile per trip.
class TripProfile extends Equatable {
  /// Unique identifier for the profile (same as tripId, one-to-one relationship).
  final String id;

  /// Associated trip ID.
  final String tripId;

  /// Traveler's name.
  final String? travelerName;

  /// Traveler's email.
  final String? email;

  /// Additional notes about the traveler or trip setup.
  final String? notes;

  /// When the profile was created.
  final DateTime createdAt;

  /// When the profile was last updated.
  final DateTime updatedAt;

  const TripProfile({
    required this.id,
    required this.tripId,
    this.travelerName,
    this.email,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        tripId,
        travelerName,
        email,
        notes,
        createdAt,
        updatedAt,
      ];
}

