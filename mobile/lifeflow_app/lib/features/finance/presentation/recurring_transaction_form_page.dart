import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/finance/domain/recurring_transaction.dart';
import 'package:lifeflow_app/features/finance/domain/recurring_transaction_repository.dart';
import 'package:lifeflow_app/features/finance/domain/transaction.dart';
import 'package:lifeflow_app/features/finance/presentation/categories_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/people_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/recurring_transactions_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class RecurringTransactionFormPage extends ConsumerStatefulWidget {
  const RecurringTransactionFormPage({this.initial, super.key});
  final RecurringTransaction? initial;

  @override
  ConsumerState<RecurringTransactionFormPage> createState() => _State();
}

class _State extends ConsumerState<RecurringTransactionFormPage> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _description, _amount, _dayOfMonth;
  late TransactionType _type;
  String? _categoryId, _personId;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _paused = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final x = widget.initial;
    _description = TextEditingController(text: x?.description);
    _amount = TextEditingController(
      text: x?.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _dayOfMonth = TextEditingController(text: x?.dayOfMonth.toString());
    _type = x?.type ?? TransactionType.expense;
    _categoryId = x?.categoryId;
    _personId = x?.personId;
    _startDate = x?.startDate ?? DateTime.now();
    _endDate = x?.endDate;
    _paused = x?.paused ?? false;
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _dayOfMonth.dispose();
    super.dispose();
  }

  double? _money(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return double.tryParse(
      t.contains(',') ? t.replaceAll('.', '').replaceAll(',', '.') : t,
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _error = 'Selecione uma categoria.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final draft = RecurringTransactionDraft(
      categoryId: _categoryId!,
      personId: _personId,
      description: _description.text,
      type: _type,
      amount: _money(_amount.text)!,
      dayOfMonth: int.parse(_dayOfMonth.text.trim()),
      startDate: _startDate,
      endDate: _endDate,
      paused: _paused,
    );
    try {
      final controller = ref.read(recurringTransactionsControllerProvider.notifier);
      if (widget.initial == null) {
        await controller.create(draft);
      } else {
        await controller.updateRecurringTransaction(widget.initial!.id, draft);
      }
      if (mounted) context.pop();
    } on RecurringTransactionFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesControllerProvider).value ?? const [];
    final people = ref.watch(peopleControllerProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? 'Nova recorrência' : 'Editar recorrência',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _key,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Despesa'),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Receita'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLength: 160,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Informe a descrição.'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Ex.: Assinatura de streaming',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [
                  for (final category in categories)
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(category.description),
                    ),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _personId,
                decoration: const InputDecoration(labelText: 'Pessoa (opcional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Ninguém')),
                  for (final person in people)
                    DropdownMenuItem(value: person.id, child: Text(person.name)),
                ],
                onChanged: (v) => setState(() => _personId = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amount,
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
                    child: TextFormField(
                      controller: _dayOfMonth,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        return n == null || n < 1 || n > 28
                            ? 'Dia entre 1 e 28.'
                            : null;
                      },
                      decoration: const InputDecoration(labelText: 'Dia do mês'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Início'),
                        child: Text(formatDate(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fim (opcional)',
                        ),
                        child: Text(_endDate == null ? '—' : formatDate(_endDate!)),
                      ),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _paused,
                title: const Text('Pausada'),
                subtitle: const Text('Não gera novas ocorrências enquanto pausada'),
                onChanged: (v) => setState(() => _paused = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: context.colors.critical)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(
                  widget.initial == null
                      ? 'SALVAR RECORRÊNCIA'
                      : 'SALVAR ALTERAÇÕES',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecurringTransactionEditRoutePage extends ConsumerWidget {
  const RecurringTransactionEditRoutePage({required this.recurringId, super.key});
  final String recurringId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(recurringTransactionDetailsProvider(recurringId)).when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => const Scaffold(
          body: Center(child: Text('Recorrência indisponível.')),
        ),
        data: (item) => RecurringTransactionFormPage(initial: item),
      );
}
