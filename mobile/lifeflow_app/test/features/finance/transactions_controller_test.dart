import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/finance/data/supabase_transaction_repository.dart';
import 'package:lifeflow_app/features/finance/domain/transaction.dart';
import 'package:lifeflow_app/features/finance/domain/transaction_repository.dart';
import 'package:lifeflow_app/features/finance/presentation/transactions_controller.dart';

void main() {
  test('cria, edita e remove transação', () async {
    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(_Fake())],
    );
    addTearDown(container.dispose);
    await container.read(transactionsControllerProvider.future);
    final controller = container.read(transactionsControllerProvider.notifier);

    final created = await controller.create(_draft(50));
    expect(created.amount, 50);
    expect(created.isEditable, isTrue);

    await controller.updateTransaction(created.id, _draft(80));
    expect(
      container.read(transactionsControllerProvider).value?.single.amount,
      80,
    );

    await controller.delete(created.id);
    expect(container.read(transactionsControllerProvider).value, isEmpty);
  });

  test('cria compra parcelada com N transações vinculadas', () async {
    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(_Fake())],
    );
    addTearDown(container.dispose);
    await container.read(transactionsControllerProvider.future);
    final controller = container.read(transactionsControllerProvider.notifier);

    final installments = await controller.createInstallmentPurchase(
      _draft(300),
      3,
    );
    expect(installments, hasLength(3));
    expect(
      installments.map((t) => t.installmentGroupId).toSet(),
      hasLength(1),
    );
    expect(
      installments.map((t) => t.installmentIndex).toList(),
      [1, 2, 3],
    );
    expect(
      container.read(transactionsControllerProvider).value,
      hasLength(3),
    );
  });
}

TransactionDraft _draft(double amount) => TransactionDraft(
  categoryId: 'category-id',
  transactionDate: DateTime.utc(2026, 9, 20),
  description: 'Compra',
  type: TransactionType.expense,
  amount: amount,
);

class _Fake implements TransactionRepository {
  final Map<String, Transaction> _byId = {};

  @override
  Future<List<Transaction>> getTransactions() async => _byId.values.toList();

  @override
  Future<Transaction> getTransaction(String id) async => _byId[id]!;

  @override
  Future<Transaction> saveTransaction(String id, TransactionDraft draft) async {
    final transaction = Transaction(
      id: id,
      categoryId: draft.categoryId,
      personId: draft.personId,
      transactionDate: draft.transactionDate,
      description: draft.description,
      type: draft.type,
      amount: draft.amount,
      createdAt: DateTime.utc(2026, 9, 20),
      updatedAt: DateTime.utc(2026, 9, 20),
    );
    _byId[id] = transaction;
    return transaction;
  }

  @override
  Future<List<Transaction>> createInstallmentPurchase(
    TransactionDraft draft,
    int installments,
  ) async {
    final groupId = 'group-id';
    final result = <Transaction>[];
    for (var index = 1; index <= installments; index++) {
      final id = 'installment-$index';
      final transaction = Transaction(
        id: id,
        categoryId: draft.categoryId,
        personId: draft.personId,
        transactionDate: DateTime.utc(2026, 9 + index - 1, 20),
        description: draft.description,
        type: draft.type,
        amount: draft.amount,
        installmentGroupId: groupId,
        installmentIndex: index,
        installmentTotal: installments,
        createdAt: DateTime.utc(2026, 9, 20),
        updatedAt: DateTime.utc(2026, 9, 20),
      );
      _byId[id] = transaction;
      result.add(transaction);
    }
    return result;
  }

  @override
  Future<void> deleteTransaction(String id) async => _byId.remove(id);
}
