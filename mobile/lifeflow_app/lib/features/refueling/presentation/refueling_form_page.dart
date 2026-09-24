import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/refueling/domain/refueling.dart';
import 'package:lifeflow_app/features/refueling/domain/refueling_repository.dart';
import 'package:lifeflow_app/features/refueling/presentation/refuelings_controller.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicles_controller.dart';

class RefuelingFormPage extends ConsumerStatefulWidget {
  const RefuelingFormPage({
    required this.vehicleId,
    this.initialOdometer = 0,
    this.initial,
    super.key,
  });
  final String vehicleId;
  final int initialOdometer;
  final Refueling? initial;
  @override
  ConsumerState<RefuelingFormPage> createState() => _State();
}

class _State extends ConsumerState<RefuelingFormPage> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController km, liters, price, total, station, notes;
  late DateTime date;
  late FuelType fuel;
  late bool full;
  bool saving = false, calculating = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final x = widget.initial;
    km = TextEditingController(
      text: (x?.odometer ?? widget.initialOdometer).toString(),
    );
    liters = TextEditingController(
      text: x?.liters.toStringAsFixed(3).replaceAll('.', ','),
    );
    price = TextEditingController(
      text: x?.unitPrice.toStringAsFixed(4).replaceAll('.', ','),
    );
    total = TextEditingController(
      text: x?.totalAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
    station = TextEditingController(text: x?.gasStation);
    notes = TextEditingController(text: x?.notes);
    date = x?.date ?? DateTime.now();
    fuel = x?.fuelType ?? FuelType.gasoline;
    full = x?.fullTank ?? false;
  }

  void _calculate(String source) {
    if (calculating) return;
    final l = _num(liters.text), p = _num(price.text), t = _num(total.text);
    calculating = true;
    if (source == 'total' && l != null && l > 0 && t != null && t > 0) {
      price.text = (t / l).toStringAsFixed(4).replaceAll('.', ',');
    } else if (l != null && l > 0 && p != null && p > 0) {
      total.text = (l * p).toStringAsFixed(2).replaceAll('.', ',');
    } else if (l != null && l > 0 && t != null && t > 0) {
      price.text = (t / l).toStringAsFixed(4).replaceAll('.', ',');
    }
    calculating = false;
  }

  @override
  void dispose() {
    for (final c in [km, liters, price, total, station, notes]) {
      c.dispose();
    }
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

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    if (DateUtils.dateOnly(date).isAfter(DateUtils.dateOnly(DateTime.now()))) {
      setState(
        () => error = 'A data do abastecimento não pode estar no futuro.',
      );
      return;
    }
    setState(() => saving = true);
    final d = RefuelingDraft(
      vehicleId: widget.vehicleId,
      date: date,
      odometer: int.parse(km.text),
      liters: _num(liters.text)!,
      unitPrice: _num(price.text)!,
      totalAmount: _num(total.text)!,
      fuelType: fuel,
      fullTank: full,
      gasStation: station.text,
      notes: notes.text,
    );
    try {
      final c = ref.read(refuelingsProvider(widget.vehicleId).notifier);
      if (widget.initial == null) {
        await c.create(d);
      } else {
        await c.updateRefueling(widget.initial!.id, d);
      }
      if (mounted) context.pop();
    } on RefuelingFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.initial == null ? 'Novo abastecimento' : 'Editar abastecimento',
      ),
    ),
    body: SafeArea(
      child: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: km,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _required,
                    decoration: const InputDecoration(
                      labelText: 'Quilometragem',
                      suffixText: 'km',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Decimal(
                    controller: liters,
                    label: 'Litros',
                    suffix: 'L',
                    onChanged: (_) => _calculate('liters'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Decimal(
                    controller: price,
                    label: 'Preço/L',
                    prefix: 'R\$ ',
                    onChanged: (_) => _calculate('price'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Decimal(
              controller: total,
              label: 'Total',
              prefix: 'R\$ ',
              onChanged: (_) => _calculate('total'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FuelType>(
              initialValue: fuel,
              decoration: const InputDecoration(labelText: 'Combustível'),
              items: [
                for (final f in FuelType.values)
                  DropdownMenuItem(value: f, child: Text(f.label)),
              ],
              onChanged: (v) => fuel = v!,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enchi o tanque'),
              value: full,
              onChanged: (v) => setState(() => full = v),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Mais opções'),
              children: [
                TextFormField(
                  controller: station,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Posto',
                    hintText: 'Opcional',
                  ),
                ),
                const SizedBox(height: 12),
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
              ],
            ),
            if (error != null)
              Text(error!, style: TextStyle(color: context.colors.critical)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : _save,
              child: Text(
                widget.initial == null
                    ? 'SALVAR ABASTECIMENTO'
                    : 'SALVAR ALTERAÇÕES',
              ),
            ),
          ],
        ),
      ),
    ),
  );
  String? _required(String? v) =>
      int.tryParse(v ?? '') == null ? 'Informe o valor.' : null;
  double? _num(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return double.tryParse(
      t.contains(',') ? t.replaceAll('.', '').replaceAll(',', '.') : t,
    );
  }
}

class _Decimal extends StatelessWidget {
  const _Decimal({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.prefix,
    this.suffix,
  });
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final String? prefix, suffix;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    onChanged: onChanged,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    validator: (v) {
      final t = v?.trim() ?? '';
      final n = double.tryParse(
        t.contains(',') ? t.replaceAll('.', '').replaceAll(',', '.') : t,
      );
      return n == null || n <= 0 ? 'Informe um valor válido.' : null;
    },
    decoration: InputDecoration(
      labelText: label,
      prefixText: prefix,
      suffixText: suffix,
    ),
  );
}

class RefuelingCreateRoutePage extends ConsumerWidget {
  const RefuelingCreateRoutePage({required this.vehicleId, super.key});
  final String vehicleId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(vehicleDetailsProvider(vehicleId))
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) =>
            const Scaffold(body: Center(child: Text('Veículo indisponível.'))),
        data: (v) => RefuelingFormPage(
          vehicleId: vehicleId,
          initialOdometer: v.currentOdometer,
        ),
      );
}
