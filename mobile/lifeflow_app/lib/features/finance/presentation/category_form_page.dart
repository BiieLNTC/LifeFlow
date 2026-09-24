import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/finance/domain/category.dart';
import 'package:lifeflow_app/features/finance/domain/category_repository.dart';
import 'package:lifeflow_app/features/finance/presentation/categories_controller.dart';

class CategoryFormPage extends ConsumerStatefulWidget {
  const CategoryFormPage({this.initial, super.key});
  final Category? initial;

  @override
  ConsumerState<CategoryFormPage> createState() => _State();
}

class _State extends ConsumerState<CategoryFormPage> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _description, _color;
  late CategoryPurpose _purpose;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final x = widget.initial;
    _description = TextEditingController(text: x?.description);
    _color = TextEditingController(text: x?.color);
    _purpose = x?.purpose ?? CategoryPurpose.both;
  }

  @override
  void dispose() {
    _description.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final draft = CategoryDraft(
      description: _description.text,
      purpose: _purpose,
      color: _color.text,
    );
    try {
      final controller = ref.read(categoriesControllerProvider.notifier);
      if (widget.initial == null) {
        await controller.create(draft);
      } else {
        await controller.updateCategory(widget.initial!.id, draft);
      }
      if (mounted) context.pop();
    } on CategoryFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.initial == null ? 'Nova categoria' : 'Editar categoria'),
    ),
    body: SafeArea(
      child: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            TextFormField(
              controller: _description,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Informe a descrição.'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Ex.: Mercado',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CategoryPurpose>(
              initialValue: _purpose,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final purpose in CategoryPurpose.values)
                  DropdownMenuItem(value: purpose, child: Text(purpose.label)),
              ],
              onChanged: (v) => setState(() => _purpose = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _color,
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                final text = v?.trim() ?? '';
                if (text.isEmpty) return null;
                return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(text)
                    ? null
                    : 'Use o formato #RRGGBB.';
              },
              decoration: const InputDecoration(
                labelText: 'Cor',
                hintText: '#61E786 (opcional)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: context.colors.critical)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(
                widget.initial == null ? 'SALVAR CATEGORIA' : 'SALVAR ALTERAÇÕES',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CategoryEditRoutePage extends ConsumerWidget {
  const CategoryEditRoutePage({required this.categoryId, super.key});
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(categoryDetailsProvider(categoryId)).when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) =>
            const Scaffold(body: Center(child: Text('Categoria indisponível.'))),
        data: (item) => CategoryFormPage(initial: item),
      );
}
