import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/finance/domain/person.dart';
import 'package:lifeflow_app/features/finance/domain/person_repository.dart';
import 'package:lifeflow_app/features/finance/presentation/people_controller.dart';

class PeoplePage extends ConsumerWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pessoas')),
      body: SafeArea(
        child: people.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            onRetry: () => ref.read(peopleControllerProvider.notifier).reload(),
          ),
          data: (items) => items.isEmpty
              ? _EmptyState(onCreate: () => context.push('/more/people/new'))
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(peopleControllerProvider.notifier).reload(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      for (final person in items) ...[
                        _PersonTile(person: person),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/more/people/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('PESSOA'),
      ),
    );
  }
}

class _PersonTile extends ConsumerWidget {
  const _PersonTile({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
    color: context.colors.surface,
    borderRadius: BorderRadius.circular(16),
    child: ListTile(
      leading: Icon(Icons.person_outline_rounded, color: context.colors.primary),
      title: Text(person.name),
      trailing: PopupMenuButton<String>(
        onSelected: (action) async {
          if (action == 'edit') {
            context.push('/more/people/${person.id}/edit');
          } else if (action == 'delete') {
            await _delete(context, ref);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Editar')),
          PopupMenuItem(value: 'delete', child: Text('Remover')),
        ],
      ),
    ),
  );

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover pessoa?'),
        content: Text('${person.name} deixará de aparecer nas suas transações.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'REMOVER',
              style: TextStyle(color: dialogContext.colors.critical),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(peopleControllerProvider.notifier).delete(person.id);
    } on PersonFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 60,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma pessoa cadastrada.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Vincule transações a quem participa das suas finanças.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('NOVA PESSOA'),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 52, color: context.colors.warning),
          const SizedBox(height: 16),
          const Text('Não foi possível carregar as pessoas.'),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRetry, child: const Text('TENTAR NOVAMENTE')),
        ],
      ),
    ),
  );
}
