// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_question_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SecretQuestionModelAdapter extends TypeAdapter<SecretQuestionModel> {
  @override
  final int typeId = 23;

  @override
  SecretQuestionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SecretQuestionModel(
      id: fields[0] as String,
      passwordId: fields[1] as String,
      question: fields[2] as String,
      encryptedAnswer: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SecretQuestionModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.passwordId)
      ..writeByte(2)
      ..write(obj.question)
      ..writeByte(3)
      ..write(obj.encryptedAnswer);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecretQuestionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
