// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_day_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItineraryDayModelAdapter extends TypeAdapter<ItineraryDayModel> {
  @override
  final int typeId = 16;

  @override
  ItineraryDayModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItineraryDayModel(
      id: fields[0] as String,
      tripId: fields[1] as String,
      date: fields[2] as DateTime,
      notes: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ItineraryDayModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItineraryDayModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
