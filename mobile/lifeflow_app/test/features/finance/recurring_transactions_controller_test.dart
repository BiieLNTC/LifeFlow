import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/finance/data/supabase_recurring_transaction_repository.dart';
import 'package:lifeflow_app/features/finance/domain/recurring_transaction.dart';
import 'package:lifeflow_app/features/finance/domain/recurring_transaction_repository.dart';
import 'package:lifeflow_app/features/finance/domain/transaction.dart';
import 'package:lifeflow_app/features/finance/presentation/recurring_transactions_controller.dart';

void main() {
  test('cria, edita, remove e gera ocorrências de recorrência', () async {
    final fake = _Fake();
    final container = ProviderContainer(
      overrides: [recurringTransactionRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    await container.read(recurringTransactionsControllerProvider.future);
    final controller = container.read(
      recurringTransactionsControllerProvider.notifier,
    );

    final created = await controller.create(_draft(100));
    expect(created.amount, 100);

    await controller.updateRecurringTransaction(created.id, _draft(150));
    expect(
      container
          .read(recurringTransactionsControllerProvider)
          .value
          ?.single
          .amount,
      150,
    );

    final generated = await controller.generateDueOccurrences();
    expect(generated, 2);

    await controller.delete(created.id);
    expect(
      container.read(recurringTransactionsControllerProvider).value,
      isEmpty,
    );
  });
}

RecurringTransactionDraft _draft(double amount) => RecurringTransactionDraft(
  categoryId: 'category-id',
  description: 'Assinatura',
  type: TransactionType.expense,
  amount: amount,
  dayOfMonth: 10,
  startDate: DateTime.utc(2026, 1, 10),
);

class _Fake implements RecurringTransactionRepository {
  RecurringTransaction? value;

  @override
  Future<List<RecurringTransaction>> getRecurringTransactions() async =>
      value == null ? [] : [value!];

  @override
  Future<RecurringTransaction> getRecurringTransaction(String id) async =>
      value!;

  @override
  Future<RecurringTransaction> saveRecurringTransaction(
    String id,
    RecurringTransactionDraft draft,
  ) async => value = RecurringTransaction(
    id: id,
    categoryId: draft.categoryId,
    personId: draft.personId,
    description: draft.description,
    type: draft.type,
    amount: draft.amount,
    dayOfMonth: draft.dayOfMonth,
    startDate: draft.startDate,
    endDate: draft.endDate,
    paused: draft.paused,
    createdAt: DateTime.utc(2026, 9, 20),
    updatedAt: DateTime.utc(2026, 9, 20),
  );

  @override
  Future<void> deleteRecurringTransaction(String id) async => value = null;

  @override
  Future<int> generateDueOccurrences() async => 2;
}
