// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PasswordModelAdapter extends TypeAdapter<PasswordModel> {
  @override
  final int typeId = 22;

  @override
  PasswordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PasswordModel(
      id: fields[0] as String,
      siteName: fields[1] as String,
      url: fields[2] as String?,
      username: fields[3] as String?,
      encryptedPassword: fields[4] as String?,
      isGoogleSignIn: fields[5] as bool,
      lastUpdated: fields[6] as DateTime,
      is2FA: fields[7] as bool,
      categoryGroup: fields[8] as String?,
      hasSecretQuestions: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PasswordModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.siteName)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.encryptedPassword)
      ..writeByte(5)
      ..write(obj.isGoogleSignIn)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.is2FA)
      ..writeByte(8)
      ..write(obj.categoryGroup)
      ..writeByte(9)
      ..write(obj.hasSecretQuestions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
