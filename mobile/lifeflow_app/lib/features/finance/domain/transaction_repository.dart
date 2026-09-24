import 'package:lifeflow_app/features/finance/domain/transaction.dart';

class TransactionFailure implements Exception {
  const TransactionFailure(this.message);
  final String message;
}

abstract interface class TransactionRepository {
  Future<List<Transaction>> getTransactions();
  Future<Transaction> getTransaction(String id);
  Future<Transaction> saveTransaction(String id, TransactionDraft draft);

  /// Cria uma compra parcelada: `installments` transações com o mesmo
  /// `installment_group_id`, datadas em meses consecutivos a partir de
  /// `draft.transactionDate`.
  Future<List<Transaction>> createInstallmentPurchase(
    TransactionDraft draft,
    int installments,
  );
  Future<void> deleteTransaction(String id);
}
