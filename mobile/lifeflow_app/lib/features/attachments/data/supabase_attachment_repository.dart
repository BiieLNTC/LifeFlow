import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/features/attachments/domain/attachment.dart';
import 'package:lifeflow_app/features/attachments/domain/attachment_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final attachmentRepositoryProvider = Provider<AttachmentRepository>(
  (ref) => SupabaseAttachmentRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseAttachmentRepository implements AttachmentRepository {
  SupabaseAttachmentRepository(this.client);
  final SupabaseClient client;
  static const bucket = 'vehicle-attachments';
  static const _uuid = Uuid();

  @override
  Future<List<Attachment>> getMaintenanceAttachments(String maintenanceId) =>
      _guard(() async {
        final rows = await client
            .from('attachments')
            .select()
            .eq('entity_type', 'maintenance')
            .eq('entity_id', maintenanceId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false);
        return rows.map(_fromJson).toList(growable: false);
      });

  @override
  Future<Attachment> uploadMaintenanceAttachment({
    required String vehicleId,
    required String maintenanceId,
    required AttachmentUpload upload,
  }) => _guard(() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw const AttachmentFailure('Sua sessão expirou. Entre novamente.');
    }
    final id = _uuid.v7();
    final extension = _extensionFor(upload.contentType);
    final path =
        'users/$userId/vehicles/$vehicleId/maintenance/$maintenanceId/$id.$extension';

    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          upload.bytes,
          fileOptions: FileOptions(
            contentType: upload.contentType,
            upsert: false,
          ),
        );
    try {
      final row = await client
          .from('attachments')
          .insert({
            'id': id,
            'vehicle_id': vehicleId,
            'entity_type': 'maintenance',
            'entity_id': maintenanceId,
            'file_name': upload.fileName.trim(),
            'content_type': upload.contentType,
            'file_size': upload.bytes.length,
            'storage_path': path,
          })
          .select()
          .single();
      return _fromJson(row);
    } catch (_) {
      try {
        await client.storage.from(bucket).remove([path]);
      } catch (_) {
        // A limpeza é uma tentativa de compensação; o erro original é preservado.
      }
      rethrow;
    }
  });

  @override
  Future<Uri> createSignedUrl(Attachment attachment) => _guard(() async {
    final url = await client.storage
        .from(bucket)
        .createSignedUrl(attachment.storagePath, 300);
    return Uri.parse(url);
  });

  @override
  Future<void> deleteAttachment(Attachment attachment) => _guard(() async {
    await client.storage.from(bucket).remove([attachment.storagePath]);
    await client
        .from('attachments')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', attachment.id)
        .select('id')
        .single();
  });

  Attachment _fromJson(Map<String, dynamic> json) => Attachment(
    id: json['id'],
    vehicleId: json['vehicle_id'],
    entityId: json['entity_id'],
    fileName: json['file_name'],
    contentType: json['content_type'],
    fileSize: json['file_size'],
    storagePath: json['storage_path'],
    createdAt: DateTime.parse(json['created_at']).toUtc(),
  );

  String _extensionFor(String contentType) => switch (contentType) {
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'application/pdf' => 'pdf',
    _ => throw const AttachmentFailure('Tipo de arquivo não permitido.'),
  };

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on StorageException catch (error) {
      throw AttachmentFailure(
        error.statusCode == '413'
            ? 'O arquivo ultrapassa o limite de 10 MB.'
            : 'Não foi possível acessar o arquivo.',
      );
    } on PostgrestException catch (error) {
      throw AttachmentFailure(
        error.code == '42501'
            ? 'Você não tem permissão para este anexo.'
            : 'Não foi possível salvar os dados do anexo.',
      );
    } catch (error) {
      if (error is AttachmentFailure) rethrow;
      throw const AttachmentFailure(
        'Não foi possível conectar ao serviço. Verifique sua internet.',
      );
    }
  }
}
