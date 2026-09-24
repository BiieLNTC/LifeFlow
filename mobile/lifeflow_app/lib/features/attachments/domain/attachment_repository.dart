import 'package:lifeflow_app/features/attachments/domain/attachment.dart';

abstract interface class AttachmentRepository {
  Future<List<Attachment>> getMaintenanceAttachments(String maintenanceId);

  Future<Attachment> uploadMaintenanceAttachment({
    required String vehicleId,
    required String maintenanceId,
    required AttachmentUpload upload,
  });

  Future<Uri> createSignedUrl(Attachment attachment);

  Future<void> deleteAttachment(Attachment attachment);
}

class AttachmentFailure implements Exception {
  const AttachmentFailure(this.message);
  final String message;
}
