// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookModelAdapter extends TypeAdapter<BookModel> {
  @override
  final int typeId = 32;

  @override
  BookModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookModel(
      id: fields[0] as String,
      title: fields[1] as String,
      primaryAuthor: fields[2] as String,
      pageCount: fields[3] as int,
      selfRating: fields[11] as double?,
      datePublished: fields[5] as DateTime?,
      dateStarted: fields[6] as DateTime?,
      dateRead: fields[7] as DateTime?,
      readHistory: (fields[8] as List?)?.cast<ReadHistoryEntryModel>(),
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BookModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.primaryAuthor)
      ..writeByte(3)
      ..write(obj.pageCount)
      ..writeByte(11)
      ..write(obj.selfRating)
      ..writeByte(5)
      ..write(obj.datePublished)
      ..writeByte(6)
      ..write(obj.dateStarted)
      ..writeByte(7)
      ..write(obj.dateRead)
      ..writeByte(8)
      ..write(obj.readHistory)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
