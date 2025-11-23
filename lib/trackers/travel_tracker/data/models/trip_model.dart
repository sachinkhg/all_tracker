import 'package:hive/hive.dart';
import '../../domain/entities/trip.dart';
import '../../core/constants.dart';

part 'trip_model.g.dart';

/// Hive model for Trip entity (typeId: 14).
@HiveType(typeId: 14)
class TripModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? destination;

  @HiveField(3)
  DateTime? startDate;

  @HiveField(4)
  DateTime? endDate;

  @HiveField(5)
  String? description;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  int? tripTypeIndex; // Store enum as int

  @HiveField(9)
  double? destinationLatitude;

  @HiveField(10)
  double? destinationLongitude;

  @HiveField(11)
  String? destinationMapLink;

  TripModel({
    required this.id,
    required this.title,
    this.destination,
    this.startDate,
    this.endDate,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.tripTypeIndex,
    this.destinationLatitude,
    this.destinationLongitude,
    this.destinationMapLink,
  });

  factory TripModel.fromEntity(Trip trip) => TripModel(
        id: trip.id,
        title: trip.title,
        destination: trip.destination,
        startDate: trip.startDate,
        endDate: trip.endDate,
        description: trip.description,
        createdAt: trip.createdAt,
        updatedAt: trip.updatedAt,
        tripTypeIndex: trip.tripType?.index,
        destinationLatitude: trip.destinationLatitude,
        destinationLongitude: trip.destinationLongitude,
        destinationMapLink: trip.destinationMapLink,
      );

  Trip toEntity() => Trip(
        id: id,
        title: title,
        tripType: tripTypeIndex != null ? TripType.values[tripTypeIndex!] : null,
        destination: destination,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
        destinationMapLink: destinationMapLink,
        startDate: startDate,
        endDate: endDate,
        description: description,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

