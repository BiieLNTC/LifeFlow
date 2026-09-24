enum LocalSyncStatus {
  synced('synced'),
  pendingCreate('pending_create'),
  pendingUpdate('pending_update'),
  pendingDelete('pending_delete'),
  failed('failed');

  const LocalSyncStatus(this.databaseValue);
  final String databaseValue;
}

enum SyncOperation {
  create('create'),
  update('update'),
  delete('delete');

  const SyncOperation(this.databaseValue);
  final String databaseValue;

  static SyncOperation fromDatabase(String value) =>
      values.firstWhere((item) => item.databaseValue == value);
}

enum SyncMutationStatus {
  pending('pending'),
  failed('failed');

  const SyncMutationStatus(this.databaseValue);
  final String databaseValue;
}

class SyncSummary {
  const SyncSummary({required this.pending, required this.failed});
  final int pending;
  final int failed;
  bool get hasIssues => pending > 0 || failed > 0;
}

class OfflineUnavailable implements Exception {
  const OfflineUnavailable();
}

class SyncConflict implements Exception {
  const SyncConflict(this.message);
  final String message;
}
