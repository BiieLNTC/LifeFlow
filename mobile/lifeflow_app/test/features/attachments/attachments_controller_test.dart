import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/attachments/data/supabase_attachment_repository.dart';
import 'package:lifeflow_app/features/attachments/domain/attachment.dart';
import 'package:lifeflow_app/features/attachments/domain/attachment_repository.dart';
import 'package:lifeflow_app/features/attachments/presentation/attachments_controller.dart';

void main() {
  test('envia e remove anexo de manutenção', () async {
    final repository = _FakeAttachmentRepository();
    final scope = (
      vehicleId: 'vehicle-id',
      maintenanceId: 'maintenance-id',
    );
    final container = ProviderContainer(
      overrides: [attachmentRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      attachmentsProvider(scope),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await container.read(attachmentsProvider(scope).future);

    final controller = container.read(attachmentsProvider(scope).notifier);
    final attachment = await controller.upload(
      AttachmentUpload(
        fileName: 'nota.pdf',
        contentType: 'application/pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );
    expect(attachment.fileName, 'nota.pdf');
    expect(container.read(attachmentsProvider(scope)).value, hasLength(1));

    await controller.delete(attachment);
    expect(container.read(attachmentsProvider(scope)).value, isEmpty);
  });
}

class _FakeAttachmentRepository implements AttachmentRepository {
  final List<Attachment> values = [];

  @override
  Future<List<Attachment>> getMaintenanceAttachments(
    String maintenanceId,
  ) async => [...values];

  @override
  Future<Attachment> uploadMaintenanceAttachment({
    required String vehicleId,
    required String maintenanceId,
    required AttachmentUpload upload,
  }) async {
    final attachment = Attachment(
      id: 'attachment-id',
      vehicleId: vehicleId,
      entityId: maintenanceId,
      fileName: upload.fileName,
      contentType: upload.contentType,
      fileSize: upload.bytes.length,
      storagePath: 'private/path.pdf',
      createdAt: DateTime.utc(2026, 9, 21),
    );
    values.insert(0, attachment);
    return attachment;
  }

  @override
  Future<Uri> createSignedUrl(Attachment attachment) async =>
      Uri.parse('https://example.test/signed');

  @override
  Future<void> deleteAttachment(Attachment attachment) async {
    values.removeWhere((item) => item.id == attachment.id);
  }
}
