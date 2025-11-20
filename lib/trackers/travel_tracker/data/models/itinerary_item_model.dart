import 'package:hive/hive.dart';
import '../../domain/entities/itinerary_item.dart';
import '../../core/constants.dart';

part 'itinerary_item_model.g.dart';

/// Hive model for ItineraryItem entity (typeId: 17).
@HiveType(typeId: 17)
class ItineraryItemModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String dayId;

  @HiveField(2)
  int typeIndex; // Store enum as int

  @HiveField(3)
  String title;

  @HiveField(4)
  DateTime? time;

  @HiveField(5)
  String? location;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  String? mapLink;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  ItineraryItemModel({
    required this.id,
    required this.dayId,
    required this.typeIndex,
    required this.title,
    this.time,
    this.location,
    this.notes,
    this.mapLink,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItineraryItemModel.fromEntity(ItineraryItem item) => ItineraryItemModel(
        id: item.id,
        dayId: item.dayId,
        typeIndex: item.type.index,
        title: item.title,
        time: item.time,
        location: item.location,
        notes: item.notes,
        mapLink: item.mapLink,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      );

  ItineraryItem toEntity() => ItineraryItem(
        id: id,
        dayId: dayId,
        type: ItineraryItemType.values[typeIndex],
        title: title,
        time: time,
        location: location,
        notes: notes,
        mapLink: mapLink,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

