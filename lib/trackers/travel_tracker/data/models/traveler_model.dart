import 'package:hive/hive.dart';
import '../../domain/entities/traveler.dart';

part 'traveler_model.g.dart';

/// Hive model for Traveler entity (typeId: 21).
@HiveType(typeId: 21)
class TravelerModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String? relationship;

  @HiveField(4)
  String? email;

  @HiveField(5)
  String? phone;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  bool isMainTraveler;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  TravelerModel({
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

  factory TravelerModel.fromEntity(Traveler traveler) => TravelerModel(
        id: traveler.id,
        tripId: traveler.tripId,
        name: traveler.name,
        relationship: traveler.relationship,
        email: traveler.email,
        phone: traveler.phone,
        notes: traveler.notes,
        isMainTraveler: traveler.isMainTraveler,
        createdAt: traveler.createdAt,
        updatedAt: traveler.updatedAt,
      );

  Traveler toEntity() => Traveler(
        id: id,
        tripId: tripId,
        name: name,
        relationship: relationship,
        email: email,
        phone: phone,
        notes: notes,
        isMainTraveler: isMainTraveler,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

