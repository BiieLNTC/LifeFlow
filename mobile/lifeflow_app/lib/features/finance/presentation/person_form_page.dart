import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/finance/domain/person.dart';
import 'package:lifeflow_app/features/finance/domain/person_repository.dart';
import 'package:lifeflow_app/features/finance/presentation/people_controller.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';

class PersonFormPage extends ConsumerStatefulWidget {
  const PersonFormPage({this.initial, super.key});
  final Person? initial;

  @override
  ConsumerState<PersonFormPage> createState() => _State();
}

class _State extends ConsumerState<PersonFormPage> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  DateTime? _birthDate;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name);
    _birthDate = widget.initial?.birthDate;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(DateTime.now().year - 30),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final draft = PersonDraft(name: _name.text, birthDate: _birthDate);
    try {
      final controller = ref.read(peopleControllerProvider.notifier);
      if (widget.initial == null) {
        await controller.create(draft);
      } else {
        await controller.updatePerson(widget.initial!.id, draft);
      }
      if (mounted) context.pop();
    } on PersonFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.initial == null ? 'Nova pessoa' : 'Editar pessoa'),
    ),
    body: SafeArea(
      child: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            TextFormField(
              controller: _name,
              maxLength: 120,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o nome.' : null,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data de nascimento (opcional)',
                ),
                child: Text(
                  _birthDate == null ? 'Não informada' : formatDate(_birthDate!),
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
              child: Text(
                widget.initial == null ? 'SALVAR PESSOA' : 'SALVAR ALTERAÇÕES',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PersonEditRoutePage extends ConsumerWidget {
  const PersonEditRoutePage({required this.personId, super.key});
  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(personDetailsProvider(personId)).when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) =>
            const Scaffold(body: Center(child: Text('Pessoa indisponível.'))),
        data: (item) => PersonFormPage(initial: item),
      );
}
