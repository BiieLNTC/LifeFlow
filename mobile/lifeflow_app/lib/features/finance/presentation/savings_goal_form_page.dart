import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/finance/domain/savings_goal.dart';
import 'package:lifeflow_app/features/finance/domain/savings_goal_repository.dart';
import 'package:lifeflow_app/features/finance/presentation/savings_goals_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class SavingsGoalFormPage extends ConsumerStatefulWidget {
  const SavingsGoalFormPage({this.initial, super.key});
  final SavingsGoal? initial;

  @override
  ConsumerState<SavingsGoalFormPage> createState() => _State();
}

class _State extends ConsumerState<SavingsGoalFormPage> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title, _amount;
  DateTime? _targetDate;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final x = widget.initial;
    _title = TextEditingController(text: x?.title);
    _amount = TextEditingController(
      text: x?.targetAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _targetDate = x?.targetDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  double? _money(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return double.tryParse(
      t.contains(',') ? t.replaceAll('.', '').replaceAll(',', '.') : t,
    );
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final draft = SavingsGoalDraft(
      title: _title.text,
      targetAmount: _money(_amount.text)!,
      targetDate: _targetDate,
    );
    try {
      final controller = ref.read(savingsGoalsControllerProvider.notifier);
      if (widget.initial == null) {
        await controller.create(draft);
      } else {
        await controller.updateSavingsGoal(widget.initial!.id, draft);
      }
      if (mounted) context.pop();
    } on SavingsGoalFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.initial == null ? 'Nova meta' : 'Editar meta'),
    ),
    body: SafeArea(
      child: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            TextFormField(
              controller: _title,
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o título.' : null,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ex.: Viagem de férias',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = _money(v ?? '');
                return n == null || n <= 0 ? 'Informe um valor válido.' : null;
              },
              decoration: const InputDecoration(
                labelText: 'Valor alvo',
                prefixText: 'R\$ ',
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickTargetDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data alvo (opcional)',
                ),
                child: Text(
                  _targetDate == null ? 'Sem prazo definido' : formatDate(_targetDate!),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: context.colors.critical)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(widget.initial == null ? 'SALVAR META' : 'SALVAR ALTERAÇÕES'),
            ),
          ],
        ),
      ),
    ),
  );
}

class SavingsGoalEditRoutePage extends ConsumerWidget {
  const SavingsGoalEditRoutePage({required this.goalId, super.key});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(savingsGoalDetailsProvider(goalId)).when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) =>
            const Scaffold(body: Center(child: Text('Meta indisponível.'))),
        data: (item) => SavingsGoalFormPage(initial: item),
      );
}
