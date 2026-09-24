import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/finance/domain/category.dart';
import 'package:lifeflow_app/features/finance/domain/category_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseCategoryRepository(
    client,
    OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
  );
});

class SupabaseCategoryRepository implements CategoryRepository {
  SupabaseCategoryRepository(this._client, this._offline);
  final SupabaseClient _client;
  final OfflineRepositorySupport _offline;

  @override
  Future<List<Category>> getCategories() => _guard(() async {
    final rows = await _offline.readList(
      entityType: 'category',
      parentId: null,
      remote: () async =>
          (await _client
                  .from('categories')
                  .select()
                  .isFilter('deleted_at', null)
                  .order('description'))
              .cast<Map<String, dynamic>>(),
    );
    final categories = rows.map(_fromJson).toList();
    categories.sort((a, b) => a.description.compareTo(b.description));
    return categories;
  });

  @override
  Future<Category> getCategory(String id) => _guard(
    () async => _fromJson(
      await _offline.readOne(
        entityType: 'category',
        recordId: id,
        remote: () => _client
            .from('categories')
            .select()
            .eq('id', id)
            .isFilter('deleted_at', null)
            .single(),
      ),
    ),
  );

  @override
  Future<Category> saveCategory(String id, CategoryDraft draft) =>
      _guard(() async {
        final payload = {'id': id, ..._draftToJson(draft), 'deleted_at': null};
        final previous = await _offline.store.readRecord(
          userId: _offline.userId,
          entityType: 'category',
          recordId: id,
        );
        final row = await _offline.save(
          entityType: 'category',
          recordId: id,
          parentId: null,
          localRecord: _localJson(id, draft, previous: previous),
          remotePayload: payload,
          remote: () =>
              _client.from('categories').upsert(payload).select().single(),
        );
        return _fromJson(row);
      });

  @override
  Future<void> deleteCategory(String id) => _guard(() async {
    await _offline.delete(
      entityType: 'category',
      recordId: id,
      parentId: null,
      remote: () async {
        await _client
            .from('categories')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id)
            .select('id')
            .single();
      },
    );
  });

  Map<String, Object?> _draftToJson(CategoryDraft draft) => {
    'description': draft.description.trim(),
    'purpose': draft.purpose.databaseValue,
    'color': _text(draft.color),
  };

  Map<String, dynamic> _localJson(
    String id,
    CategoryDraft draft, {
    Map<String, dynamic>? previous,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'id': id,
      'user_id': _offline.userId,
      ..._draftToJson(draft),
      'created_at': previous?['created_at'] ?? now,
      'updated_at': now,
      'deleted_at': null,
    };
  }

  Category _fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] as String,
    description: j['description'] as String,
    purpose: CategoryPurpose.fromDatabase(j['purpose'] as String),
    color: j['color'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
    updatedAt: DateTime.parse(j['updated_at'] as String).toUtc(),
  );

  String? _text(String? v) {
    final x = v?.trim();
    return x == null || x.isEmpty ? null : x;
  }

  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on PostgrestException catch (e) {
      throw CategoryFailure(
        e.code == '23505'
            ? 'Já existe uma categoria com este nome.'
            : e.code == '42501'
            ? 'Você não tem permissão para esta categoria.'
            : 'Revise os dados da categoria.',
      );
    } catch (e) {
      if (e is CategoryFailure) rethrow;
      throw const CategoryFailure('Não foi possível conectar ao serviço.');
    }
  }
}
