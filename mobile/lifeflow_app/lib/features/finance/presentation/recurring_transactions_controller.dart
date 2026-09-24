import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/finance/data/supabase_recurring_transaction_repository.dart';
import 'package:lifeflow_app/features/finance/domain/recurring_transaction.dart';
import 'package:uuid/uuid.dart';

final recurringTransactionsControllerProvider = AsyncNotifierProvider<
  RecurringTransactionsController,
  List<RecurringTransaction>
>(RecurringTransactionsController.new);

final recurringTransactionDetailsProvider =
    FutureProvider.family<RecurringTransaction, String>(
      (ref, id) => ref
          .watch(recurringTransactionRepositoryProvider)
          .getRecurringTransaction(id),
    );

class RecurringTransactionsController
    extends AsyncNotifier<List<RecurringTransaction>> {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<RecurringTransaction>> build() => ref
      .watch(recurringTransactionRepositoryProvider)
      .getRecurringTransactions();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(recurringTransactionRepositoryProvider)
          .getRecurringTransactions(),
    );
  }

  Future<RecurringTransaction> create(
    RecurringTransactionDraft draft,
  ) async {
    final recurring = await ref
        .read(recurringTransactionRepositoryProvider)
        .saveRecurringTransaction(_uuid.v7(), draft);
    state = AsyncData([recurring, ...?state.value]);
    return recurring;
  }

  Future<RecurringTransaction> updateRecurringTransaction(
    String id,
    RecurringTransactionDraft draft,
  ) async {
    final recurring = await ref
        .read(recurringTransactionRepositoryProvider)
        .saveRecurringTransaction(id, draft);
    state = AsyncData([
      for (final item in state.value ?? const <RecurringTransaction>[])
        if (item.id == id) recurring else item,
    ]);
    ref.invalidate(recurringTransactionDetailsProvider(id));
    return recurring;
  }

  Future<void> delete(String id) async {
    await ref
        .read(recurringTransactionRepositoryProvider)
        .deleteRecurringTransaction(id);
    state = AsyncData(
      (state.value ?? const <RecurringTransaction>[])
          .where((r) => r.id != id)
          .toList(),
    );
    ref.invalidate(recurringTransactionDetailsProvider(id));
  }

  /// Gera as ocorrências pendentes e recarrega a lista de transações
  /// recorrentes (o efeito nas transações em si é visto no
  /// [transactionsControllerProvider], que deve ser recarregado à parte).
  Future<int> generateDueOccurrences() async {
    final generated = await ref
        .read(recurringTransactionRepositoryProvider)
        .generateDueOccurrences();
    return generated;
  }
}
