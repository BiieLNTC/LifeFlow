import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/supabase/supabase_provider.dart';
import 'package:lifeflow_app/core/sync/offline_repository_support.dart';
import 'package:lifeflow_app/core/sync/offline_store.dart';
import 'package:lifeflow_app/features/finance/domain/savings_goal.dart';
import 'package:lifeflow_app/features/finance/domain/savings_goal_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSavingsGoalRepository(
    client,
    OfflineRepositorySupport(client, ref.watch(offlineStoreProvider)),
  );
});

class SupabaseSavingsGoalRepository implements SavingsGoalRepository {
  SupabaseSavingsGoalRepository(this._client, this._offline);
  final SupabaseClient _client;
  final OfflineRepositorySupport _offline;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<SavingsGoal>> getSavingsGoals() => _guard(() async {
    final rows = await _offline.readList(
      entityType: 'savings_goal',
      parentId: null,
      remote: () async =>
          (await _client
                  .from('savings_goals')
                  .select()
                  .isFilter('deleted_at', null)
                  .order('created_at', ascending: false))
              .cast<Map<String, dynamic>>(),
    );
    final goals = rows.map(_fromJson).toList();
    goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return goals;
  });

  @override
  Future<SavingsGoal> getSavingsGoal(String id) => _guard(
    () async => _fromJson(
      await _offline.readOne(
        entityType: 'savings_goal',
        recordId: id,
        remote: () => _client
            .from('savings_goals')
            .select()
            .eq('id', id)
            .isFilter('deleted_at', null)
            .single(),
      ),
    ),
  );

  @override
  Future<SavingsGoal> saveSavingsGoal(String id, SavingsGoalDraft draft) =>
      _guard(() async {
        final payload = {
          'id': id,
          ..._draftToJson(draft),
          'deleted_at': null,
        };
        final previous = await _offline.store.readRecord(
          userId: _offline.userId,
          entityType: 'savings_goal',
          recordId: id,
        );
        final row = await _offline.save(
          entityType: 'savings_goal',
          recordId: id,
          parentId: null,
          localRecord: _localJson(id, draft, previous: previous),
          remotePayload: payload,
          remote: () =>
              _client.from('savings_goals').upsert(payload).select().single(),
        );
        return _fromJson(row);
      });

  @override
  Future<void> deleteSavingsGoal(String id) => _guard(() async {
    await _offline.delete(
      entityType: 'savings_goal',
      recordId: id,
      parentId: null,
      remote: () async {
        await _client
            .from('savings_goals')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id)
            .select('id')
            .single();
      },
    );
  });

  @override
  Future<List<GoalContribution>> getContributions(String goalId) =>
      _guard(() async {
        final rows = await _offline.readList(
          entityType: 'goal_contribution',
          parentId: goalId,
          parentIdField: 'goal_id',
          remote: () async =>
              (await _client
                      .from('goal_contributions')
                      .select()
                      .eq('goal_id', goalId)
                      .order('contribution_date', ascending: false))
                  .cast<Map<String, dynamic>>(),
        );
        final contributions = rows.map(_contributionFromJson).toList();
        contributions.sort(
          (a, b) => b.contributionDate.compareTo(a.contributionDate),
        );
        return contributions;
      });

  @override
  Future<GoalContribution> addContribution(GoalContributionDraft draft) =>
      _guard(() async {
        final id = _uuid.v7();
        final payload = {
          'id': id,
          'goal_id': draft.goalId,
          'transaction_id': draft.transactionId,
          'amount': draft.amount,
          'contribution_date': draft.contributionDate.toIso8601String().split(
            'T',
          ).first,
        };
        final row = await _offline.save(
          entityType: 'goal_contribution',
          recordId: id,
          parentId: draft.goalId,
          localRecord: {
            ...payload,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          },
          remotePayload: payload,
          remote: () => _client
              .from('goal_contributions')
              .insert(payload)
              .select()
              .single(),
        );
        return _contributionFromJson(row);
      });

  @override
  Future<void> deleteContribution(String id, {required String goalId}) =>
      _guard(() async {
        await _offline.delete(
          entityType: 'goal_contribution',
          recordId: id,
          parentId: goalId,
          remote: () async {
            await _client.from('goal_contributions').delete().eq('id', id);
          },
        );
      });

  Map<String, Object?> _draftToJson(SavingsGoalDraft draft) => {
    'title': draft.title.trim(),
    'target_amount': draft.targetAmount,
    'target_date': draft.targetDate?.toIso8601String().split('T').first,
  };

  Map<String, dynamic> _localJson(
    String id,
    SavingsGoalDraft draft, {
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

  SavingsGoal _fromJson(Map<String, dynamic> j) => SavingsGoal(
    id: j['id'] as String,
    title: j['title'] as String,
    targetAmount: _number(j['target_amount']),
    targetDate: j['target_date'] == null
        ? null
        : DateTime.parse(j['target_date'] as String),
    createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
    updatedAt: DateTime.parse(j['updated_at'] as String).toUtc(),
  );

  GoalContribution _contributionFromJson(Map<String, dynamic> j) =>
      GoalContribution(
        id: j['id'] as String,
        goalId: j['goal_id'] as String,
        transactionId: j['transaction_id'] as String?,
        amount: _number(j['amount']),
        contributionDate: DateTime.parse(j['contribution_date'] as String),
        createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
      );

  double _number(Object v) =>
      v is num ? v.toDouble() : double.parse(v as String);

  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on PostgrestException catch (e) {
      throw SavingsGoalFailure(
        e.code == '42501'
            ? 'Você não tem permissão para esta meta.'
            : 'Revise os dados da meta.',
      );
    } catch (e) {
      if (e is SavingsGoalFailure) rethrow;
      throw const SavingsGoalFailure('Não foi possível conectar ao serviço.');
    }
  }
}
