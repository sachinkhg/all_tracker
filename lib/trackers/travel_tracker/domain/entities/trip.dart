import 'package:equatable/equatable.dart';
import '../../core/constants.dart';

/// Domain model for a Trip.
///
/// Represents a travel trip with basic information like title, dates, and destination.
/// This is the main entity that groups all travel-related data.
class Trip extends Equatable {
  /// Unique identifier for the trip (GUID recommended).
  final String id;

  /// Title/name of the trip.
  final String title;

  /// Type of trip (work or leisure).
  final TripType? tripType;

  /// Destination(s) for the trip.
  final String? destination;

  /// Latitude coordinate for the destination.
  final double? destinationLatitude;

  /// Longitude coordinate for the destination.
  final double? destinationLongitude;

  /// Map link (Google Maps or Apple Maps URL) for the destination.
  final String? destinationMapLink;

  /// Start date of the trip.
  final DateTime? startDate;

  /// End date of the trip.
  final DateTime? endDate;

  /// Optional description or notes about the trip.
  final String? description;

  /// When the trip was created.
  final DateTime createdAt;

  /// When the trip was last updated.
  final DateTime updatedAt;

  const Trip({
    required this.id,
    required this.title,
    this.tripType,
    this.destination,
    this.destinationLatitude,
    this.destinationLongitude,
    this.destinationMapLink,
    this.startDate,
    this.endDate,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        tripType,
        destination,
        destinationLatitude,
        destinationLongitude,
        destinationMapLink,
        startDate,
        endDate,
        description,
        createdAt,
        updatedAt,
      ];
}

