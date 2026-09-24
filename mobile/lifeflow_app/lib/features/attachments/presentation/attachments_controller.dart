import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/attachments/data/supabase_attachment_repository.dart';
import 'package:lifeflow_app/features/attachments/domain/attachment.dart';

typedef AttachmentScope = ({String vehicleId, String maintenanceId});

final attachmentsProvider =
    AsyncNotifierProvider.family<
      AttachmentsController,
      List<Attachment>,
      AttachmentScope
    >(AttachmentsController.new);

class AttachmentsController extends AsyncNotifier<List<Attachment>> {
  AttachmentsController(this.scope);
  final AttachmentScope scope;

  @override
  Future<List<Attachment>> build() => ref
      .watch(attachmentRepositoryProvider)
      .getMaintenanceAttachments(scope.maintenanceId);

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(attachmentRepositoryProvider)
          .getMaintenanceAttachments(scope.maintenanceId),
    );
  }

  Future<Attachment> upload(AttachmentUpload upload) async {
    final attachment = await ref
        .read(attachmentRepositoryProvider)
        .uploadMaintenanceAttachment(
          vehicleId: scope.vehicleId,
          maintenanceId: scope.maintenanceId,
          upload: upload,
        );
    state = AsyncData([attachment, ...?state.value]);
    return attachment;
  }

  Future<Uri> createSignedUrl(Attachment attachment) =>
      ref.read(attachmentRepositoryProvider).createSignedUrl(attachment);

  Future<void> delete(Attachment attachment) async {
    await ref.read(attachmentRepositoryProvider).deleteAttachment(attachment);
    state = AsyncData(
      (state.value ?? const <Attachment>[])
          .where((item) => item.id != attachment.id)
          .toList(growable: false),
    );
  }
}
