import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/core/sync/sync_service.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';

class SyncPage extends ConsumerStatefulWidget {
  const SyncPage({super.key});

  @override
  ConsumerState<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends ConsumerState<SyncPage> {
  bool _syncing = false;

  Future<void> _sync({bool retryFailed = false}) async {
    setState(() => _syncing = true);
    try {
      await ref.read(syncRunnerProvider)(retryFailed: retryFailed);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(syncSummaryProvider).value;
    final hasFailure = (summary?.failed ?? 0) > 0;
    final hasPending = (summary?.pending ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Sincronização')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            Icon(
              hasFailure
                  ? Icons.sync_problem_rounded
                  : hasPending
                  ? Icons.cloud_off_rounded
                  : Icons.cloud_done_rounded,
              size: 56,
              color: hasFailure
                  ? context.colors.critical
                  : hasPending
                  ? context.colors.warning
                  : context.colors.primary,
            ),
            const SizedBox(height: 20),
            Text(
              hasFailure
                  ? 'Algumas alterações precisam de revisão'
                  : hasPending
                  ? 'Alterações aguardando conexão'
                  : 'Tudo sincronizado',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              hasFailure
                  ? '${summary!.failed} alteração(ões) foram rejeitadas pelo servidor.'
                  : hasPending
                  ? '${summary!.pending} alteração(ões) serão enviadas assim que houver conexão.'
                  : 'Todos os seus dados estão salvos no servidor.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _syncing ? null : () => _sync(retryFailed: hasFailure),
              icon: _syncing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(hasFailure ? 'TENTAR NOVAMENTE' : 'SINCRONIZAR AGORA'),
            ),
          ],
        ),
      ),
    );
  }
}
