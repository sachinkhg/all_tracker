// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripProfileModelAdapter extends TypeAdapter<TripProfileModel> {
  @override
  final int typeId = 15;

  @override
  TripProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripProfileModel(
      id: fields[0] as String,
      tripId: fields[1] as String,
      travelerName: fields[2] as String?,
      email: fields[3] as String?,
      notes: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TripProfileModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.travelerName)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
