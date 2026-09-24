import 'dart:typed_data';

class Attachment {
  const Attachment({
    required this.id,
    required this.vehicleId,
    required this.entityId,
    required this.fileName,
    required this.contentType,
    required this.fileSize,
    required this.storagePath,
    required this.createdAt,
  });

  final String id;
  final String vehicleId;
  final String entityId;
  final String fileName;
  final String contentType;
  final int fileSize;
  final String storagePath;
  final DateTime createdAt;

  bool get isPdf => contentType == 'application/pdf';
}

class AttachmentUpload {
  const AttachmentUpload({
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
}
