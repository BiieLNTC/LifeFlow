import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/finance/domain/person.dart';
import 'package:lifeflow_app/features/finance/domain/person_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final personRepositoryProvider = Provider<PersonRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabasePersonRepository(
    client,
    OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
  );
});

class SupabasePersonRepository implements PersonRepository {
  SupabasePersonRepository(this._client, this._offline);
  final SupabaseClient _client;
  final OfflineRepositorySupport _offline;

  @override
  Future<List<Person>> getPeople() => _guard(() async {
    final rows = await _offline.readList(
      entityType: 'person',
      parentId: null,
      remote: () async =>
          (await _client
                  .from('people')
                  .select()
                  .isFilter('deleted_at', null)
                  .order('name'))
              .cast<Map<String, dynamic>>(),
    );
    final people = rows.map(_fromJson).toList();
    people.sort((a, b) => a.name.compareTo(b.name));
    return people;
  });

  @override
  Future<Person> getPerson(String id) => _guard(
    () async => _fromJson(
      await _offline.readOne(
        entityType: 'person',
        recordId: id,
        remote: () => _client
            .from('people')
            .select()
            .eq('id', id)
            .isFilter('deleted_at', null)
            .single(),
      ),
    ),
  );

  @override
  Future<Person> savePerson(String id, PersonDraft draft) => _guard(() async {
    final payload = {'id': id, ..._draftToJson(draft), 'deleted_at': null};
    final previous = await _offline.store.readRecord(
      userId: _offline.userId,
      entityType: 'person',
      recordId: id,
    );
    final row = await _offline.save(
      entityType: 'person',
      recordId: id,
      parentId: null,
      localRecord: _localJson(id, draft, previous: previous),
      remotePayload: payload,
      remote: () => _client.from('people').upsert(payload).select().single(),
    );
    return _fromJson(row);
  });

  @override
  Future<void> deletePerson(String id) => _guard(() async {
    await _offline.delete(
      entityType: 'person',
      recordId: id,
      parentId: null,
      remote: () async {
        await _client
            .from('people')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id)
            .select('id')
            .single();
      },
    );
  });

  Map<String, Object?> _draftToJson(PersonDraft draft) => {
    'name': draft.name.trim(),
    'birth_date': draft.birthDate?.toIso8601String().split('T').first,
  };

  Map<String, dynamic> _localJson(
    String id,
    PersonDraft draft, {
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

  Person _fromJson(Map<String, dynamic> j) => Person(
    id: j['id'] as String,
    name: j['name'] as String,
    birthDate: j['birth_date'] == null
        ? null
        : DateTime.parse(j['birth_date'] as String),
    createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
    updatedAt: DateTime.parse(j['updated_at'] as String).toUtc(),
  );

  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on PostgrestException catch (e) {
      throw PersonFailure(
        e.code == '42501'
            ? 'Você não tem permissão para esta pessoa.'
            : 'Revise os dados da pessoa.',
      );
    } catch (e) {
      if (e is PersonFailure) rethrow;
      throw const PersonFailure('Não foi possível conectar ao serviço.');
    }
  }
}
