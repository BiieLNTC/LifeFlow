import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/maintenance/domain/maintenance.dart';
import 'package:lifeflow_app/features/maintenance/domain/maintenance_repository.dart';
import 'package:lifeflow_app/features/maintenance/presentation/maintenance_controller.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder.dart';
import 'package:lifeflow_app/features/reminders/domain/reminder_repository.dart';
import 'package:lifeflow_app/features/reminders/presentation/reminders_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicles_controller.dart';
import 'package:uuid/uuid.dart';

class MaintenanceFormPage extends ConsumerStatefulWidget {
  const MaintenanceFormPage({
    required this.vehicleId,
    this.initialOdometer = 0,
    this.initialMaintenance,
    super.key,
  });
  final String vehicleId;
  final int initialOdometer;
  final Maintenance? initialMaintenance;

  @override
  ConsumerState<MaintenanceFormPage> createState() =>
      _MaintenanceFormPageState();
}

class _MaintenanceFormPageState extends ConsumerState<MaintenanceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  late final TextEditingController _odometerController;
  late final TextEditingController _workshopController;
  late final TextEditingController _notesController;
  late DateTime _date;
  late MaintenanceType _type;
  final List<_ItemFields> _items = [];
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.initialMaintenance != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMaintenance;
    _date = initial?.date ?? DateTime.now();
    _type = initial?.type ?? MaintenanceType.preventive;
    _odometerController = TextEditingController(
      text: (initial?.odometer ?? widget.initialOdometer).toString(),
    );
    _workshopController = TextEditingController(text: initial?.workshop);
    _notesController = TextEditingController(text: initial?.notes);
    if (initial == null) {
      _items.add(_ItemFields(id: _uuid.v7(), onChanged: _refreshTotal));
    } else {
      for (final item in initial.items) {
        _items.add(_ItemFields.fromItem(item, onChanged: _refreshTotal));
      }
    }
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _workshopController.dispose();
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _refreshTotal() {
    if (mounted) setState(() {});
  }

  void _addItem() {
    setState(() {
      _items.add(_ItemFields(id: _uuid.v7(), onChanged: _refreshTotal));
    });
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;
    setState(() => _items.removeAt(index).dispose());
  }

  double get _total => _items.fold(
    0,
    (sum, item) => sum + _money(item.part.text) + _money(item.labor.text),
  );

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Data da manutenção',
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickNextDate(_ItemFields item) async {
    final firstDate = _date.add(const Duration(days: 1));
    final initialDate =
        item.nextDate != null && !item.nextDate!.isBefore(firstDate)
        ? item.nextDate!
        : firstDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2200),
      helpText: 'Próxima troca',
    );
    if (selected != null) setState(() => item.nextDate = selected);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (DateUtils.dateOnly(_date).isAfter(DateUtils.dateOnly(DateTime.now()))) {
      setState(() => _error = 'A data da manutenção não pode estar no futuro.');
      return;
    }
    if (_items.any(
      (item) => item.nextDate != null && !item.nextDate!.isAfter(_date),
    )) {
      setState(
        () => _error = 'A próxima troca deve ser posterior à manutenção.',
      );
      return;
    }
    final odometer = int.parse(_odometerController.text);
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final draft = MaintenanceDraft(
      vehicleId: widget.vehicleId,
      date: _date,
      odometer: odometer,
      type: _type,
      workshop: _workshopController.text,
      notes: _notesController.text,
      items: [
        for (final item in _items)
          MaintenanceItemDraft(
            id: item.id,
            category: item.category,
            description: item.description.text,
            partAmount: _money(item.part.text),
            laborAmount: _money(item.labor.text),
            nextReplacementOdometer: _optionalInt(item.nextOdometer.text),
            nextReplacementDate: item.nextDate,
          ),
      ],
    );

    try {
      final controller = ref.read(
        maintenancesProvider(widget.vehicleId).notifier,
      );
      final result = _isEditing
          ? await controller.updateMaintenance(
              widget.initialMaintenance!.id,
              draft,
            )
          : await controller.create(draft);
      if (mounted) {
        if (!_isEditing) await _offerReminders(result);
        if (!mounted) return;
        context.go('/vehicles/${widget.vehicleId}/maintenances/${result.id}');
      }
    } on MaintenanceFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _offerReminders(Maintenance maintenance) async {
    final items = maintenance.items
        .where((item) => item.hasNextReplacement)
        .toList();
    if (items.isEmpty || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(items.length == 1 ? 'Criar lembrete?' : 'Criar lembretes?'),
        content: Text(
          items.length == 1
              ? 'Quer acompanhar a próxima troca de ${items.single.description}?'
              : 'Quer acompanhar as próximas trocas dos ${items.length} itens?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('AGORA NÃO'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('CRIAR'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final controller = ref.read(remindersProvider(widget.vehicleId).notifier);
      for (final item in items) {
        await controller.create(
          ReminderDraft(
            vehicleId: widget.vehicleId,
            description: item.description,
            targetOdometer: item.nextReplacementOdometer,
            targetDate: item.nextReplacementDate,
            originMaintenanceId: maintenance.id,
          ),
        );
      }
    } on ReminderFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'A manutenção foi salva, mas ${failure.message.toLowerCase()}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar manutenção' : 'Nova manutenção'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              SegmentedButton<MaintenanceType>(
                segments: const [
                  ButtonSegment(
                    value: MaintenanceType.preventive,
                    label: Text('Preventiva'),
                  ),
                  ButtonSegment(
                    value: MaintenanceType.corrective,
                    label: Text('Corretiva'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: _isSaving
                    ? null
                    : (value) => setState(() => _type = value.first),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _odometerController,
                      enabled: !_isSaving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      validator: (value) => int.tryParse(value ?? '') == null
                          ? 'Informe o KM.'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Quilometragem',
                        suffixText: 'km',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _isSaving ? null : _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Data'),
                        child: Text(formatDate(_date)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Itens',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < _items.length; index++) ...[
                _ItemEditor(
                  index: index,
                  fields: _items[index],
                  maintenanceOdometer:
                      int.tryParse(_odometerController.text) ?? 0,
                  enabled: !_isSaving,
                  canRemove: _items.length > 1,
                  onRemove: () => _removeItem(index),
                  onPickDate: () => _pickNextDate(_items[index]),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _addItem,
                icon: const Icon(Icons.add_rounded),
                label: const Text('ADICIONAR ITEM'),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    formatCurrency(_total),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _workshopController,
                enabled: !_isSaving,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Oficina',
                  hintText: 'Opcional',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                enabled: !_isSaving,
                maxLength: 2000,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Opcional',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: context.colors.critical),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isEditing ? 'SALVAR ALTERAÇÕES' : 'SALVAR MANUTENÇÃO',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _money(String value) => _parseMoney(value) ?? 0;
  int? _optionalInt(String value) =>
      value.trim().isEmpty ? null : int.tryParse(value.trim());
}

class MaintenanceCreateRoutePage extends ConsumerWidget {
  const MaintenanceCreateRoutePage({required this.vehicleId, super.key});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(vehicleDetailsProvider(vehicleId))
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) =>
            const Scaffold(body: Center(child: Text('Veículo indisponível.'))),
        data: (vehicle) => MaintenanceFormPage(
          vehicleId: vehicleId,
          initialOdometer: vehicle.currentOdometer,
        ),
      );
}

class _ItemFields {
  _ItemFields({required this.id, required VoidCallback onChanged})
    : description = TextEditingController(),
      part = TextEditingController(),
      labor = TextEditingController(),
      nextOdometer = TextEditingController() {
    part.addListener(onChanged);
    labor.addListener(onChanged);
  }

  factory _ItemFields.fromItem(
    MaintenanceItem item, {
    required VoidCallback onChanged,
  }) {
    final fields = _ItemFields(id: item.id, onChanged: onChanged);
    fields.category = item.category;
    fields.description.text = item.description;
    fields.part.text = item.partAmount == 0
        ? ''
        : item.partAmount.toStringAsFixed(2).replaceAll('.', ',');
    fields.labor.text = item.laborAmount == 0
        ? ''
        : item.laborAmount.toStringAsFixed(2).replaceAll('.', ',');
    fields.nextOdometer.text = item.nextReplacementOdometer?.toString() ?? '';
    fields.nextDate = item.nextReplacementDate;
    return fields;
  }

  final String id;
  MaintenanceCategory category = MaintenanceCategory.oil;
  final TextEditingController description;
  final TextEditingController part;
  final TextEditingController labor;
  final TextEditingController nextOdometer;
  DateTime? nextDate;

  void dispose() {
    description.dispose();
    part.dispose();
    labor.dispose();
    nextOdometer.dispose();
  }
}

class _ItemEditor extends StatelessWidget {
  const _ItemEditor({
    required this.index,
    required this.fields,
    required this.maintenanceOdometer,
    required this.enabled,
    required this.canRemove,
    required this.onRemove,
    required this.onPickDate,
  });
  final int index;
  final _ItemFields fields;
  final int maintenanceOdometer;
  final bool enabled;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Item ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (canRemove)
              IconButton(
                onPressed: enabled ? onRemove : null,
                tooltip: 'Remover item',
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        DropdownButtonFormField<MaintenanceCategory>(
          initialValue: fields.category,
          decoration: const InputDecoration(labelText: 'Categoria'),
          items: [
            for (final category in MaintenanceCategory.values)
              DropdownMenuItem(value: category, child: Text(category.label)),
          ],
          onChanged: enabled ? (value) => fields.category = value! : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: fields.description,
          enabled: enabled,
          maxLength: 160,
          textCapitalization: TextCapitalization.sentences,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Descreva o serviço.'
              : null,
          decoration: const InputDecoration(
            labelText: 'Descrição',
            hintText: 'Ex.: Troca de óleo',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MoneyField(
                controller: fields.part,
                label: 'Peças',
                enabled: enabled,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MoneyField(
                controller: fields.labor,
                label: 'Mão de obra',
                enabled: enabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: fields.nextOdometer,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) return null;
            final next = int.tryParse(value);
            return next == null || next <= maintenanceOdometer
                ? 'Deve ser maior que o KM atual.'
                : null;
          },
          decoration: const InputDecoration(
            labelText: 'Próxima troca por KM',
            suffixText: 'km',
            hintText: 'Opcional',
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: enabled ? onPickDate : null,
          borderRadius: BorderRadius.circular(16),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Próxima troca por data',
            ),
            child: Text(
              fields.nextDate == null
                  ? 'Não informada'
                  : formatDate(fields.nextDate!),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.controller,
    required this.label,
    required this.enabled,
  });
  final TextEditingController controller;
  final String label;
  final bool enabled;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (value) {
      if (value == null || value.trim().isEmpty) return null;
      final number = _parseMoney(value);
      return number == null || number < 0 ? 'Valor inválido.' : null;
    },
    decoration: InputDecoration(labelText: label, prefixText: 'R\$ '),
  );
}

double? _parseMoney(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  final normalized = text.contains(',')
      ? text.replaceAll('.', '').replaceAll(',', '.')
      : text;
  return double.tryParse(normalized);
}
