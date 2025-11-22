// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  @override
  final int typeId = 20;

  @override
  ExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    // MIGRATION: Handle old schema (8 fields) to new schema (10 fields)
    // Old schema: fields 0-6 same, field 7 = createdAt (DateTime), field 8 = updatedAt (DateTime)
    // New schema: fields 0-6 same, field 7 = paidBy (String?), field 8 = createdAt (DateTime), field 9 = updatedAt (DateTime)
    // WARNING: This migration logic must be preserved if regenerating this file with build_runner
    
    // Check if this is old format: either numOfFields == 8 OR field 7 is a DateTime (old createdAt)
    // If field 7 exists and is a DateTime, it's old format
    final field7 = fields[7];
    final isOldFormat = numOfFields == 8 || (field7 != null && field7 is DateTime);
    
    if (isOldFormat) {
      // Old format - migrate to new format
      return ExpenseModel(
        id: fields[0] as String,
        tripId: fields[1] as String,
        date: fields[2] as DateTime,
        categoryIndex: fields[3] as int,
        amount: fields[4] as double,
        currency: fields[5] as String,
        description: fields[6] as String?,
        paidBy: null, // New field, default to null for old data
        createdAt: fields[7] as DateTime, // Was at field 7, now at field 8
        updatedAt: fields[8] as DateTime, // Was at field 8, now at field 9
      );
    } else {
      // New format (10 fields) - try to read with migration fallback
      try {
        return ExpenseModel(
          id: fields[0] as String,
          tripId: fields[1] as String,
          date: fields[2] as DateTime,
          categoryIndex: fields[3] as int,
          amount: fields[4] as double,
          currency: fields[5] as String,
          description: fields[6] as String?,
          paidBy: fields.containsKey(7) && fields[7] is String ? fields[7] as String? : null,
          createdAt: fields[8] as DateTime,
          updatedAt: fields[9] as DateTime,
        );
      } catch (e) {
        // Fallback: if field 7 is a DateTime (old data that wasn't caught), treat as old format
        if (fields.containsKey(7) && fields[7] is DateTime) {
          return ExpenseModel(
            id: fields[0] as String,
            tripId: fields[1] as String,
            date: fields[2] as DateTime,
            categoryIndex: fields[3] as int,
            amount: fields[4] as double,
            currency: fields[5] as String,
            description: fields[6] as String?,
            paidBy: null,
            createdAt: fields[7] as DateTime,
            updatedAt: fields[8] as DateTime,
          );
        }
        rethrow;
      }
    }
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.categoryIndex)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.paidBy)
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
      other is ExpenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
