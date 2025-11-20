import 'package:hive/hive.dart';
import '../../domain/entities/photo.dart';

part 'photo_model.g.dart';

/// Hive model for Photo entity (typeId: 19).
@HiveType(typeId: 19)
class PhotoModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String journalEntryId;

  @HiveField(2)
  String filePath;

  @HiveField(3)
  String? caption;

  @HiveField(4)
  DateTime? dateTaken;

  @HiveField(5)
  DateTime? taggedDay;

  @HiveField(6)
  String? taggedLocation;

  @HiveField(7)
  DateTime createdAt;

  PhotoModel({
    required this.id,
    required this.journalEntryId,
    required this.filePath,
    this.caption,
    this.dateTaken,
    this.taggedDay,
    this.taggedLocation,
    required this.createdAt,
  });

  factory PhotoModel.fromEntity(Photo photo) => PhotoModel(
        id: photo.id,
        journalEntryId: photo.journalEntryId,
        filePath: photo.filePath,
        caption: photo.caption,
        dateTaken: photo.dateTaken,
        taggedDay: photo.taggedDay,
        taggedLocation: photo.taggedLocation,
        createdAt: photo.createdAt,
      );

  Photo toEntity() => Photo(
        id: id,
        journalEntryId: journalEntryId,
        filePath: filePath,
        caption: caption,
        dateTaken: dateTaken,
        taggedDay: taggedDay,
        taggedLocation: taggedLocation,
        createdAt: createdAt,
      );
}

