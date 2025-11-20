import 'package:hive/hive.dart';
import '../../domain/entities/itinerary_day.dart';

part 'itinerary_day_model.g.dart';

/// Hive model for ItineraryDay entity (typeId: 16).
@HiveType(typeId: 16)
class ItineraryDayModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String? notes;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  ItineraryDayModel({
    required this.id,
    required this.tripId,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItineraryDayModel.fromEntity(ItineraryDay day) => ItineraryDayModel(
        id: day.id,
        tripId: day.tripId,
        date: day.date,
        notes: day.notes,
        createdAt: day.createdAt,
        updatedAt: day.updatedAt,
      );

  ItineraryDay toEntity() => ItineraryDay(
        id: id,
        tripId: tripId,
        date: date,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

