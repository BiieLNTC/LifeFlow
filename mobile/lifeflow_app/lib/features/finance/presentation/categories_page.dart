import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/finance/domain/category.dart';
import 'package:lifeflow_app/features/finance/domain/category_repository.dart';
import 'package:lifeflow_app/features/finance/presentation/categories_controller.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: SafeArea(
        child: categories.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            onRetry: () =>
                ref.read(categoriesControllerProvider.notifier).reload(),
          ),
          data: (items) => items.isEmpty
              ? _EmptyState(onCreate: () => context.push('/more/categories/new'))
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(categoriesControllerProvider.notifier).reload(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      for (final category in items) ...[
                        _CategoryTile(category: category),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/more/categories/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('CATEGORIA'),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});
  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = category.color == null
        ? context.colors.primary
        : Color(int.parse('FF${category.color!.substring(1)}', radix: 16));
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, radius: 10),
        title: Text(category.description),
        subtitle: Text(category.purpose.label),
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'edit') {
              context.push('/more/categories/${category.id}/edit');
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
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover categoria?'),
        content: Text(
          'Transações que já usam "${category.description}" continuam com o histórico preservado.',
        ),
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
      await ref.read(categoriesControllerProvider.notifier).delete(category.id);
    } on CategoryFailure catch (error) {
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
            Icons.category_outlined,
            size: 60,
            color: context.colors.textSecondary,
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma categoria cadastrada.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Categorias organizam suas transações por tipo de gasto ou receita.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('NOVA CATEGORIA'),
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
          Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: context.colors.warning,
          ),
          const SizedBox(height: 16),
          const Text('Não foi possível carregar as categorias.'),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRetry, child: const Text('TENTAR NOVAMENTE')),
        ],
      ),
    ),
  );
}
