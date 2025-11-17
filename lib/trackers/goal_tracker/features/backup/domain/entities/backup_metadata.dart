import 'package:equatable/equatable.dart';

/// Domain entity representing backup metadata.
class BackupMetadata extends Equatable {
  final String id;
  final String fileName;
  final DateTime createdAt;
  final String deviceId;
  final String? deviceDescription;
  final int sizeBytes;
  final bool isE2EE;

  const BackupMetadata({
    required this.id,
    required this.fileName,
    required this.createdAt,
    required this.deviceId,
    this.deviceDescription,
    required this.sizeBytes,
    required this.isE2EE,
  });

  @override
  List<Object?> get props => [
        id,
        fileName,
        createdAt,
        deviceId,
        deviceDescription,
        sizeBytes,
        isE2EE,
      ];
}


