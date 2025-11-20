// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItineraryItemModelAdapter extends TypeAdapter<ItineraryItemModel> {
  @override
  final int typeId = 17;

  @override
  ItineraryItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItineraryItemModel(
      id: fields[0] as String,
      dayId: fields[1] as String,
      typeIndex: fields[2] as int,
      title: fields[3] as String,
      time: fields[4] as DateTime?,
      location: fields[5] as String?,
      notes: fields[6] as String?,
      mapLink: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ItineraryItemModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dayId)
      ..writeByte(2)
      ..write(obj.typeIndex)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.time)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.mapLink)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItineraryItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
