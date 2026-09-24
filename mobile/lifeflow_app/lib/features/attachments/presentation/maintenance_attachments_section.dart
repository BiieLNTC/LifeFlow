import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/attachments/domain/attachment.dart';
import 'package:lifeflow_app/features/attachments/domain/attachment_repository.dart';
import 'package:lifeflow_app/features/attachments/presentation/attachments_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class MaintenanceAttachmentsSection extends ConsumerStatefulWidget {
  const MaintenanceAttachmentsSection({
    required this.vehicleId,
    required this.maintenanceId,
    super.key,
  });

  final String vehicleId;
  final String maintenanceId;

  @override
  ConsumerState<MaintenanceAttachmentsSection> createState() =>
      _MaintenanceAttachmentsSectionState();
}

class _MaintenanceAttachmentsSectionState
    extends ConsumerState<MaintenanceAttachmentsSection> {
  bool _isUploading = false;
  String? _busyAttachmentId;

  AttachmentScope get _scope =>
      (vehicleId: widget.vehicleId, maintenanceId: widget.maintenanceId);

  Future<void> _pickAndUpload() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (file == null || !mounted) return;
    final contentType = _contentType(file.extension);
    if (contentType == null) {
      _showError('Tipo de arquivo não permitido.');
      return;
    }
    final reportedLength = file.lengthSync();
    if (reportedLength != null && reportedLength > 10 * 1024 * 1024) {
      _showError('Escolha um arquivo de até 10 MB.');
      return;
    }
    if (file.name.trim().isEmpty || file.name.length > 255) {
      _showError('O nome do arquivo é inválido ou muito longo.');
      return;
    }

    setState(() => _isUploading = true);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        throw const AttachmentFailure('Escolha um arquivo de até 10 MB.');
      }
      await ref
          .read(attachmentsProvider(_scope).notifier)
          .upload(
            AttachmentUpload(
              fileName: file.name,
              contentType: contentType,
              bytes: bytes,
            ),
          );
    } on AttachmentFailure catch (failure) {
      _showError(failure.message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _open(Attachment attachment) async {
    setState(() => _busyAttachmentId = attachment.id);
    try {
      final url = await ref
          .read(attachmentsProvider(_scope).notifier)
          .createSignedUrl(attachment);
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened) _showError('Nenhum aplicativo conseguiu abrir o arquivo.');
    } on AttachmentFailure catch (failure) {
      _showError(failure.message);
    } finally {
      if (mounted) setState(() => _busyAttachmentId = null);
    }
  }

  Future<void> _delete(Attachment attachment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover anexo?'),
        content: Text(attachment.fileName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'REMOVER',
              style: TextStyle(color: context.colors.critical),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyAttachmentId = attachment.id);
    try {
      await ref.read(attachmentsProvider(_scope).notifier).delete(attachment);
    } on AttachmentFailure catch (failure) {
      _showError(failure.message);
    } finally {
      if (mounted) setState(() => _busyAttachmentId = null);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String? _contentType(String? extension) => switch (extension?.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'pdf' => 'application/pdf',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attachmentsProvider(_scope));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Anexos',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: _isUploading ? null : _pickAndUpload,
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('ADICIONAR'),
            ),
          ],
        ),
        Text(
          'Fotos, notas fiscais ou comprovantes em JPEG, PNG ou PDF.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (_isUploading) const LinearProgressIndicator(),
        state.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () =>
                  ref.read(attachmentsProvider(_scope).notifier).reload(),
              child: const Text('TENTAR NOVAMENTE'),
            ),
          ),
          data: (attachments) => attachments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Nenhum anexo nesta manutenção.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : Column(
                  children: [
                    for (final attachment in attachments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          attachment.isPdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.image_outlined,
                          color: context.colors.primary,
                        ),
                        title: Text(
                          attachment.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_formatSize(attachment.fileSize)),
                        onTap: _busyAttachmentId == attachment.id
                            ? null
                            : () => _open(attachment),
                        trailing: _busyAttachmentId == attachment.id
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                tooltip: 'Remover anexo',
                                onPressed: () => _delete(attachment),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
    }
    return '${(bytes / 1024).ceil()} KB';
  }
}
