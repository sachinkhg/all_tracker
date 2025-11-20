import 'package:hive/hive.dart';
import '../../domain/entities/journal_entry.dart';

part 'journal_entry_model.g.dart';

/// Hive model for JournalEntry entity (typeId: 18).
@HiveType(typeId: 18)
class JournalEntryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String content;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  JournalEntryModel({
    required this.id,
    required this.tripId,
    required this.date,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalEntryModel.fromEntity(JournalEntry entry) => JournalEntryModel(
        id: entry.id,
        tripId: entry.tripId,
        date: entry.date,
        content: entry.content,
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
      );

  JournalEntry toEntity() => JournalEntry(
        id: id,
        tripId: tripId,
        date: date,
        content: content,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

