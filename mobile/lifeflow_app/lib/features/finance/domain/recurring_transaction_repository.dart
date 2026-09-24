import 'package:lifeflow_app/features/finance/domain/recurring_transaction.dart';

class RecurringTransactionFailure implements Exception {
  const RecurringTransactionFailure(this.message);
  final String message;
}

abstract interface class RecurringTransactionRepository {
  Future<List<RecurringTransaction>> getRecurringTransactions();
  Future<RecurringTransaction> getRecurringTransaction(String id);
  Future<RecurringTransaction> saveRecurringTransaction(
    String id,
    RecurringTransactionDraft draft,
  );
  Future<void> deleteRecurringTransaction(String id);

  /// Gera, para o usuário da sessão, as ocorrências pendentes até a data
  /// atual. Chamada pelo client ao abrir a tela de finanças — nunca em cron.
  /// Retorna a quantidade de transações geradas.
  Future<int> generateDueOccurrences();
}
