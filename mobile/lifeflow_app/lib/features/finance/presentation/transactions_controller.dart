import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/finance/data/supabase_transaction_repository.dart';
import 'package:lifeflow_app/features/finance/domain/transaction.dart';
import 'package:uuid/uuid.dart';

final transactionsControllerProvider =
    AsyncNotifierProvider<TransactionsController, List<Transaction>>(
      TransactionsController.new,
    );

final transactionDetailsProvider = FutureProvider.family<Transaction, String>(
  (ref, id) => ref.watch(transactionRepositoryProvider).getTransaction(id),
);

class TransactionsController extends AsyncNotifier<List<Transaction>> {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Transaction>> build() =>
      ref.watch(transactionRepositoryProvider).getTransactions();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(transactionRepositoryProvider).getTransactions(),
    );
  }

  Future<Transaction> create(TransactionDraft draft) async {
    final transaction = await ref
        .read(transactionRepositoryProvider)
        .saveTransaction(_uuid.v7(), draft);
    state = AsyncData([transaction, ...?state.value]);
    return transaction;
  }

  Future<List<Transaction>> createInstallmentPurchase(
    TransactionDraft draft,
    int installments,
  ) async {
    final transactions = await ref
        .read(transactionRepositoryProvider)
        .createInstallmentPurchase(draft, installments);
    state = AsyncData([...transactions, ...?state.value]);
    return transactions;
  }

  Future<Transaction> updateTransaction(String id, TransactionDraft draft) async {
    final transaction = await ref
        .read(transactionRepositoryProvider)
        .saveTransaction(id, draft);
    state = AsyncData([
      for (final item in state.value ?? const <Transaction>[])
        if (item.id == id) transaction else item,
    ]);
    ref.invalidate(transactionDetailsProvider(id));
    return transaction;
  }

  Future<void> delete(String id) async {
    await ref.read(transactionRepositoryProvider).deleteTransaction(id);
    state = AsyncData(
      (state.value ?? const <Transaction>[]).where((t) => t.id != id).toList(),
    );
    ref.invalidate(transactionDetailsProvider(id));
  }
}
