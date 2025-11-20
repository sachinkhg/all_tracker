import 'package:hive/hive.dart';
import '../../domain/entities/trip_profile.dart';

part 'trip_profile_model.g.dart';

/// Hive model for TripProfile entity (typeId: 15).
@HiveType(typeId: 15)
class TripProfileModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  String? travelerName;

  @HiveField(3)
  String? email;

  @HiveField(4)
  String? notes;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  TripProfileModel({
    required this.id,
    required this.tripId,
    this.travelerName,
    this.email,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripProfileModel.fromEntity(TripProfile profile) => TripProfileModel(
        id: profile.id,
        tripId: profile.tripId,
        travelerName: profile.travelerName,
        email: profile.email,
        notes: profile.notes,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      );

  TripProfile toEntity() => TripProfile(
        id: id,
        tripId: tripId,
        travelerName: travelerName,
        email: email,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

