import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/finance/domain/recurring_transaction.dart';
import 'package:lifeflow_app/features/finance/domain/recurring_transaction_repository.dart';
import 'package:lifeflow_app/features/finance/domain/transaction.dart';
import 'package:lifeflow_app/features/finance/domain/transaction_repository.dart';
import 'package:lifeflow_app/features/finance/presentation/categories_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/people_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/recurring_transactions_controller.dart';
import 'package:lifeflow_app/features/finance/presentation/transactions_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

enum _EntryMode { single, installment, recurring }

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({this.initial, super.key});
  final Transaction? initial;

  @override
  ConsumerState<TransactionFormPage> createState() => _State();
}

class _State extends ConsumerState<TransactionFormPage> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _description, _amount, _installments, _dayOfMonth;
  late TransactionType _type;
  late _EntryMode _mode;
  String? _categoryId, _personId;
  late DateTime _date;
  DateTime? _endDate;
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
    _installments = TextEditingController(text: '2');
    _dayOfMonth = TextEditingController(
      text: (x?.transactionDate.day ?? DateTime.now().day).toString(),
    );
    _type = x?.type ?? TransactionType.expense;
    _mode = _EntryMode.single;
    _categoryId = x?.categoryId;
    _personId = x?.personId;
    _date = x?.transactionDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    _installments.dispose();
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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
    try {
      if (widget.initial != null) {
        final draft = TransactionDraft(
          categoryId: _categoryId!,
          personId: _personId,
          transactionDate: _date,
          description: _description.text,
          type: _type,
          amount: _money(_amount.text)!,
        );
        await ref
            .read(transactionsControllerProvider.notifier)
            .updateTransaction(widget.initial!.id, draft);
      } else if (_mode == _EntryMode.recurring) {
        final day = int.parse(_dayOfMonth.text.trim());
        final draft = RecurringTransactionDraft(
          categoryId: _categoryId!,
          personId: _personId,
          description: _description.text,
          type: _type,
          amount: _money(_amount.text)!,
          dayOfMonth: day,
          startDate: DateTime.now(),
          endDate: _endDate,
        );
        await ref.read(recurringTransactionsControllerProvider.notifier).create(draft);
      } else {
        final draft = TransactionDraft(
          categoryId: _categoryId!,
          personId: _personId,
          transactionDate: _date,
          description: _description.text,
          type: _type,
          amount: _money(_amount.text)!,
        );
        if (_mode == _EntryMode.installment) {
          final installments = int.parse(_installments.text.trim());
          await ref
              .read(transactionsControllerProvider.notifier)
              .createInstallmentPurchase(draft, installments);
        } else {
          await ref.read(transactionsControllerProvider.notifier).create(draft);
        }
      }
      if (mounted) context.pop();
    } on TransactionFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on RecurringTransactionFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditingLocked = widget.initial != null && !widget.initial!.isEditable;
    final categories = ref.watch(categoriesControllerProvider).value ?? const [];
    final people = ref.watch(peopleControllerProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Nova transação' : 'Editar transação'),
      ),
      body: SafeArea(
        child: isEditingLocked
            ? _LockedNotice(source: widget.initial!.source!)
            : Form(
                key: _key,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  children: [
                    if (widget.initial == null) ...[
                      SegmentedButton<_EntryMode>(
                        segments: const [
                          ButtonSegment(
                            value: _EntryMode.single,
                            label: Text('Única'),
                          ),
                          ButtonSegment(
                            value: _EntryMode.installment,
                            label: Text('Parcelada'),
                          ),
                          ButtonSegment(
                            value: _EntryMode.recurring,
                            label: Text('Recorrente'),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (v) => setState(() => _mode = v.first),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                        hintText: 'Ex.: Supermercado',
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
                      decoration: const InputDecoration(
                        labelText: 'Pessoa (opcional)',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Ninguém')),
                        for (final person in people)
                          DropdownMenuItem(
                            value: person.id,
                            child: Text(person.name),
                          ),
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
                            decoration: InputDecoration(
                              labelText: _mode == _EntryMode.installment
                                  ? 'Valor da parcela'
                                  : 'Valor',
                              prefixText: 'R\$ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_mode == _EntryMode.recurring)
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
                              decoration: const InputDecoration(
                                labelText: 'Dia do mês',
                              ),
                            ),
                          )
                        else if (_mode == _EntryMode.installment)
                          Expanded(
                            child: TextFormField(
                              controller: _installments,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final n = int.tryParse(v?.trim() ?? '');
                                return n == null || n < 2
                                    ? 'Mínimo 2 parcelas.'
                                    : null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Parcelas',
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: InkWell(
                              onTap: _pickDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Data'),
                                child: Text(formatDate(_date)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_mode == _EntryMode.recurring) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickEndDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Repetir até (opcional)',
                          ),
                          child: Text(
                            _endDate == null ? 'Sem data de término' : formatDate(_endDate!),
                          ),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: context.colors.critical)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saveLabel()),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _saveLabel() {
    if (widget.initial != null) return 'SALVAR ALTERAÇÕES';
    return switch (_mode) {
      _EntryMode.single => 'SALVAR TRANSAÇÃO',
      _EntryMode.installment => 'SALVAR PARCELAMENTO',
      _EntryMode.recurring => 'SALVAR RECORRÊNCIA',
    };
  }
}

class _LockedNotice extends StatelessWidget {
  const _LockedNotice({required this.source});
  final TransactionSource source;

  @override
  Widget build(BuildContext context) {
    final label = switch (source) {
      TransactionSource.maintenance => 'uma manutenção',
      TransactionSource.refueling => 'um abastecimento',
      TransactionSource.vehicleExpense => 'uma despesa de veículo',
      TransactionSource.recurring => 'uma transação recorrente',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 52, color: context.colors.warning),
            const SizedBox(height: 20),
            Text(
              'Esta transação foi gerada automaticamente a partir de $label.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Para alterá-la, edite o registro de origem.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionEditRoutePage extends ConsumerWidget {
  const TransactionEditRoutePage({required this.transactionId, super.key});
  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(transactionDetailsProvider(transactionId)).when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) =>
            const Scaffold(body: Center(child: Text('Transação indisponível.'))),
        data: (item) => TransactionFormPage(initial: item),
      );
}
