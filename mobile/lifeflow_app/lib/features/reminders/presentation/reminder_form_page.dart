import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder_repository.dart';
import 'package:lifeflow_app/features/reminders/presentation/reminders_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class ReminderFormPage extends ConsumerStatefulWidget {
  const ReminderFormPage({required this.vehicleId, this.initial, super.key});
  final String vehicleId;
  final Reminder? initial;

  @override
  ConsumerState<ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends ConsumerState<ReminderFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _odometerController;
  DateTime? _targetDate;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initial?.description,
    );
    _odometerController = TextEditingController(
      text: widget.initial?.targetOdometer?.toString(),
    );
    _targetDate = widget.initial?.targetDate;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
      helpText: 'Data do lembrete',
    );
    if (selected != null) setState(() => _targetDate = selected);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final targetOdometer = int.tryParse(_odometerController.text);
    if (targetOdometer == null && _targetDate == null) {
      setState(() => _error = 'Informe uma quilometragem, uma data ou ambas.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final draft = ReminderDraft(
      vehicleId: widget.vehicleId,
      description: _descriptionController.text,
      targetOdometer: targetOdometer,
      targetDate: _targetDate,
      originMaintenanceId: widget.initial?.originMaintenanceId,
      status: widget.initial?.status ?? ReminderStatus.active,
    );
    try {
      final controller = ref.read(remindersProvider(widget.vehicleId).notifier);
      if (widget.initial == null) {
        await controller.create(draft);
      } else {
        await controller.updateReminder(widget.initial!.id, draft);
      }
      if (mounted) context.pop();
    } on ReminderFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.initial == null ? 'Novo lembrete' : 'Editar lembrete'),
    ),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSaving,
              maxLength: 160,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o cuidado desejado.'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Ex.: Troca de óleo',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quando avisar',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Use quilometragem, data ou os dois critérios.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _odometerController,
              enabled: !_isSaving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                return int.tryParse(value) == null
                    ? 'Informe uma quilometragem válida.'
                    : null;
              },
              decoration: const InputDecoration(
                labelText: 'Quilometragem alvo',
                hintText: 'Opcional',
                suffixText: 'km',
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _isSaving ? null : _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data alvo',
                  suffixIcon: _targetDate == null
                      ? const Icon(Icons.calendar_today_rounded)
                      : IconButton(
                          tooltip: 'Remover data',
                          onPressed: _isSaving
                              ? null
                              : () => setState(() => _targetDate = null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                child: Text(
                  _targetDate == null ? 'Opcional' : formatDate(_targetDate!),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: context.colors.critical)),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.initial == null
                          ? 'SALVAR LEMBRETE'
                          : 'SALVAR ALTERAÇÕES',
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ReminderEditRoutePage extends ConsumerWidget {
  const ReminderEditRoutePage({
    required this.vehicleId,
    required this.reminderId,
    super.key,
  });
  final String vehicleId;
  final String reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(reminderDetailsProvider(reminderId))
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) =>
            const Scaffold(body: Center(child: Text('Lembrete indisponível.'))),
        data: (reminder) =>
            ReminderFormPage(vehicleId: vehicleId, initial: reminder),
      );
}
