import 'package:hive/hive.dart';
import '../../domain/entities/trip.dart';

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

  TripModel({
    required this.id,
    required this.title,
    this.destination,
    this.startDate,
    this.endDate,
    this.description,
    required this.createdAt,
    required this.updatedAt,
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
      );

  Trip toEntity() => Trip(
        id: id,
        title: title,
        destination: destination,
        startDate: startDate,
        endDate: endDate,
        description: description,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

