import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/expenses/domain/expense.dart';
import 'package:lifeflow_app/features/expenses/domain/expense_repository.dart';
import 'package:lifeflow_app/features/expenses/presentation/expenses_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class ExpenseFormPage extends ConsumerStatefulWidget {
  const ExpenseFormPage({required this.vehicleId, this.initial, super.key});
  final String vehicleId;
  final Expense? initial;
  @override
  ConsumerState<ExpenseFormPage> createState() => _State();
}

class _State extends ConsumerState<ExpenseFormPage> {
  final key = GlobalKey<FormState>();
  late final TextEditingController amount, description, notes;
  late ExpenseCategory category;
  late DateTime date;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final x = widget.initial;
    amount = TextEditingController(
      text: x?.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    description = TextEditingController(text: x?.description);
    notes = TextEditingController(text: x?.notes);
    category = x?.category ?? ExpenseCategory.other;
    date = x?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final x = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (x != null) setState(() => date = x);
  }

  double? _money(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return double.tryParse(
      t.contains(',') ? t.replaceAll('.', '').replaceAll(',', '.') : t,
    );
  }

  Future<void> _save() async {
    if (!key.currentState!.validate()) return;
    if (DateUtils.dateOnly(date).isAfter(DateUtils.dateOnly(DateTime.now()))) {
      setState(() => error = 'A data da despesa não pode estar no futuro.');
      return;
    }
    setState(() => saving = true);
    final d = ExpenseDraft(
      vehicleId: widget.vehicleId,
      category: category,
      date: date,
      amount: _money(amount.text)!,
      description: description.text,
      notes: notes.text,
    );
    try {
      final c = ref.read(expensesProvider(widget.vehicleId).notifier);
      if (widget.initial == null) {
        await c.create(d);
      } else {
        await c.updateExpense(widget.initial!.id, d);
      }
      if (mounted) context.pop();
    } on ExpenseFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.initial == null ? 'Nova despesa' : 'Editar despesa'),
    ),
    body: SafeArea(
      child: Form(
        key: key,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                for (final x in ExpenseCategory.values)
                  DropdownMenuItem(value: x, child: Text(x.label)),
              ],
              onChanged: (x) => category = x!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: description,
              maxLength: 160,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe a descrição.' : null,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Ex.: Seguro anual',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final n = _money(v ?? '');
                      return n == null || n <= 0
                          ? 'Informe um valor válido.'
                          : null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pick,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data'),
                      child: Text(formatDate(date)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: notes,
              maxLength: 2000,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Opcional',
              ),
            ),
            if (error != null)
              Text(error!, style: TextStyle(color: context.colors.critical)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : _save,
              child: Text(
                widget.initial == null ? 'SALVAR DESPESA' : 'SALVAR ALTERAÇÕES',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ExpenseEditRoutePage extends ConsumerWidget {
  const ExpenseEditRoutePage({
    required this.vehicleId,
    required this.expenseId,
    super.key,
  });
  final String vehicleId, expenseId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(expenseDetailsProvider(expenseId))
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) =>
            const Scaffold(body: Center(child: Text('Despesa indisponível.'))),
        data: (x) => ExpenseFormPage(vehicleId: vehicleId, initial: x),
      );
}
