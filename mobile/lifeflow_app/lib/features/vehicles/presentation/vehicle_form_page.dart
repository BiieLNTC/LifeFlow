import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/vehicles/data/fipe_vehicle_catalog_repository.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle_catalog.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle_repository.dart';
import 'package:lifeflow_app/features/vehicles/presentation/catalog_picker.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicle_formatters.dart';
import 'package:lifeflow_app/features/vehicles/presentation/vehicles_controller.dart';

class VehicleFormPage extends ConsumerStatefulWidget {
  const VehicleFormPage({this.initialVehicle, super.key});

  final Vehicle? initialVehicle;

  @override
  ConsumerState<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends ConsumerState<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandFieldKey = GlobalKey<FormFieldState<String>>();
  final _modelFieldKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _nicknameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _versionController;
  late final TextEditingController _manufactureYearController;
  late final TextEditingController _modelYearController;
  late final TextEditingController _plateController;
  late final TextEditingController _odometerController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _notesController;
  late VehicleType _vehicleType;
  FuelType? _fuelType;
  DateTime? _purchaseDate;
  bool _isSaving = false;
  bool _isLoadingBrands = false;
  bool _isLoadingModels = false;
  bool _manualCatalog = false;
  bool _nicknameWasEdited = false;
  List<VehicleCatalogOption> _brands = const [];
  List<VehicleCatalogOption> _models = const [];
  VehicleCatalogOption? _selectedBrand;
  String? _catalogError;
  String? _errorMessage;

  bool get _isEditing => widget.initialVehicle != null;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.initialVehicle;
    _vehicleType = vehicle?.type ?? VehicleType.car;
    _fuelType = vehicle?.fuelType;
    _purchaseDate = vehicle?.purchaseDate;
    _nicknameController = TextEditingController(text: vehicle?.nickname);
    _brandController = TextEditingController(text: vehicle?.brand);
    _modelController = TextEditingController(text: vehicle?.model);
    _versionController = TextEditingController(text: vehicle?.version);
    _manufactureYearController = TextEditingController(
      text: vehicle?.manufactureYear?.toString(),
    );
    _modelYearController = TextEditingController(
      text: vehicle?.modelYear?.toString(),
    );
    _plateController = TextEditingController(text: vehicle?.licensePlate);
    _odometerController = TextEditingController(
      text: (vehicle?.currentOdometer ?? 0).toString(),
    );
    _purchasePriceController = TextEditingController(
      text: vehicle?.purchasePrice?.toStringAsFixed(2).replaceAll('.', ','),
    );
    _notesController = TextEditingController(text: vehicle?.notes);
    _nicknameWasEdited = vehicle != null;
    _loadBrands();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _versionController.dispose();
    _manufactureYearController.dispose();
    _modelYearController.dispose();
    _plateController.dispose();
    _odometerController.dispose();
    _purchasePriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseDate != null &&
        DateUtils.dateOnly(_purchaseDate!)
            .isAfter(DateUtils.dateOnly(DateTime.now()))) {
      setState(
        () => _errorMessage = 'A data da compra não pode estar no futuro.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final draft = VehicleDraft(
      type: _vehicleType,
      nickname: _nicknameController.text,
      brand: _brandController.text,
      model: _modelController.text,
      version: _versionController.text,
      manufactureYear: _optionalInt(_manufactureYearController.text),
      modelYear: _optionalInt(_modelYearController.text),
      licensePlate: _plateController.text,
      fuelType: _fuelType,
      currentOdometer: int.parse(_odometerController.text),
      purchaseDate: _purchaseDate,
      purchasePrice: _optionalMoney(_purchasePriceController.text),
      notes: _notesController.text,
    );

    try {
      final controller = ref.read(vehiclesControllerProvider.notifier);
      final vehicle = _isEditing
          ? await controller.updateVehicle(widget.initialVehicle!.id, draft)
          : await controller.create(draft);

      if (mounted) context.go('/vehicles/${vehicle.id}');
    } on VehicleFailure catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Não foi possível salvar o veículo.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _loadBrands() async {
    final requestedType = _vehicleType;
    setState(() {
      _isLoadingBrands = true;
      _catalogError = null;
    });

    try {
      final brands = await ref
          .read(vehicleCatalogRepositoryProvider)
          .getBrands(requestedType);
      if (!mounted || _vehicleType != requestedType) return;
      setState(() => _brands = brands);
    } on VehicleCatalogFailure catch (error) {
      if (!mounted || _vehicleType != requestedType) return;
      setState(() => _catalogError = error.message);
    } finally {
      if (mounted && _vehicleType == requestedType) {
        setState(() => _isLoadingBrands = false);
      }
    }
  }

  Future<void> _loadModels(VehicleCatalogOption brand) async {
    setState(() {
      _isLoadingModels = true;
      _catalogError = null;
      _models = const [];
    });

    try {
      final models = await ref
          .read(vehicleCatalogRepositoryProvider)
          .getModels(_vehicleType, brand.code);
      if (!mounted || _selectedBrand?.code != brand.code) return;
      setState(() => _models = models);
    } on VehicleCatalogFailure catch (error) {
      if (!mounted) return;
      setState(() => _catalogError = error.message);
    } finally {
      if (mounted && _selectedBrand?.code == brand.code) {
        setState(() => _isLoadingModels = false);
      }
    }
  }

  Future<void> _selectBrand() async {
    final selected = await showCatalogPicker(
      context: context,
      title: 'Escolha a marca',
      options: _brands,
    );
    if (selected == null || !mounted) return;

    setState(() {
      _selectedBrand = selected;
      _brandController.text = selected.name;
      _modelController.clear();
    });
    _brandFieldKey.currentState?.didChange(selected.name);
    _modelFieldKey.currentState?.didChange('');
    await _loadModels(selected);
  }

  Future<void> _selectModel() async {
    final selected = await showCatalogPicker(
      context: context,
      title: 'Escolha o modelo',
      options: _models,
    );
    if (selected == null || !mounted) return;

    setState(() {
      _modelController.text = selected.name;
      if (!_nicknameWasEdited || _nicknameController.text.trim().isEmpty) {
        _nicknameController.text = _suggestNickname(selected.name);
        _nicknameWasEdited = false;
      }
    });
    _modelFieldKey.currentState?.didChange(selected.name);
  }

  void _changeVehicleType(VehicleType type) {
    if (type == _vehicleType) return;
    setState(() {
      _vehicleType = type;
      _selectedBrand = null;
      _brands = const [];
      _models = const [];
      _brandController.clear();
      _modelController.clear();
      _catalogError = null;
      if (!_nicknameWasEdited) _nicknameController.clear();
    });
    _brandFieldKey.currentState?.didChange('');
    _modelFieldKey.currentState?.didChange('');
    if (!_manualCatalog) _loadBrands();
  }

  void _useManualCatalog() {
    setState(() {
      _manualCatalog = true;
      _catalogError = null;
    });
  }

  void _useOnlineCatalog() {
    setState(() {
      _manualCatalog = false;
      _selectedBrand = null;
      _brandController.clear();
      _modelController.clear();
    });
    _loadBrands();
  }

  String _suggestNickname(String modelName) {
    return modelName.trim().split(RegExp(r'\s+')).first;
  }

  Future<void> _pickPurchaseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Data da compra',
    );

    if (selected != null) setState(() => _purchaseDate = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar veículo' : 'Novo veículo'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              Text(
                _isEditing ? 'Atualize o essencial.' : 'Quem está na garagem?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Poucos dados agora. O restante pode ser preenchido quando quiser.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              SegmentedButton<VehicleType>(
                segments: const [
                  ButtonSegment(
                    value: VehicleType.car,
                    icon: Icon(Icons.directions_car_rounded),
                    label: Text('Carro'),
                  ),
                  ButtonSegment(
                    value: VehicleType.motorcycle,
                    icon: Icon(Icons.two_wheeler_rounded),
                    label: Text('Moto'),
                  ),
                ],
                selected: {_vehicleType},
                onSelectionChanged: _isSaving
                    ? null
                    : (selection) => _changeVehicleType(selection.first),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nicknameController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                onChanged: (_) => _nicknameWasEdited = true,
                validator: (value) =>
                    _requiredText(value, 'Informe um apelido.'),
                decoration: const InputDecoration(
                  labelText: 'Apelido',
                  hintText: 'Ex.: i30',
                  prefixIcon: Icon(Icons.favorite_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              if (_manualCatalog) ...[
                TextFormField(
                  controller: _brandController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  validator: (value) =>
                      _requiredText(value, 'Informe a marca.'),
                  decoration: const InputDecoration(labelText: 'Marca'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _modelController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  onChanged: (value) {
                    if (!_nicknameWasEdited ||
                        _nicknameController.text.trim().isEmpty) {
                      _nicknameController.text = value.trim().isEmpty
                          ? ''
                          : _suggestNickname(value);
                      _nicknameWasEdited = false;
                    }
                  },
                  validator: (value) =>
                      _requiredText(value, 'Informe o modelo.'),
                  decoration: const InputDecoration(labelText: 'Modelo'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isSaving ? null : _useOnlineCatalog,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('USAR CATÁLOGO'),
                  ),
                ),
              ] else ...[
                _CatalogSelectionField(
                  fieldKey: _brandFieldKey,
                  label: 'Marca',
                  value: _brandController.text,
                  isLoading: _isLoadingBrands,
                  enabled:
                      !_isSaving && !_isLoadingBrands && _brands.isNotEmpty,
                  onTap: _selectBrand,
                ),
                const SizedBox(height: 12),
                _CatalogSelectionField(
                  fieldKey: _modelFieldKey,
                  label: 'Modelo',
                  value: _modelController.text,
                  isLoading: _isLoadingModels,
                  enabled:
                      !_isSaving &&
                      !_isLoadingModels &&
                      _selectedBrand != null &&
                      _models.isNotEmpty,
                  onTap: _selectModel,
                  helperText: _selectedBrand == null
                      ? 'Escolha primeiro a marca'
                      : null,
                ),
                if (_catalogError != null)
                  _CatalogError(
                    message: _catalogError!,
                    onRetry: _selectedBrand == null
                        ? _loadBrands
                        : () => _loadModels(_selectedBrand!),
                    onManual: _useManualCatalog,
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isSaving ? null : _useManualCatalog,
                      child: const Text('PREENCHER MANUALMENTE'),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _odometerController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validateOdometer,
                decoration: const InputDecoration(
                  labelText: 'Quilometragem atual',
                  suffixText: 'km',
                ),
              ),
              const SizedBox(height: 20),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 12),
                title: const Text('Mais opções'),
                subtitle: const Text('Ano, placa, combustível e compra'),
                children: [
                  TextFormField(
                    controller: _versionController,
                    enabled: !_isSaving,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Versão',
                      hintText: 'Opcional',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _manufactureYearController,
                          enabled: !_isSaving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (value) => _validateYear(value, 2100),
                          decoration: const InputDecoration(
                            labelText: 'Ano fabricação',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _modelYearController,
                          enabled: !_isSaving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: _validateModelYear,
                          decoration: const InputDecoration(
                            labelText: 'Ano modelo',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _plateController,
                    enabled: !_isSaving,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9-]')),
                      LengthLimitingTextInputFormatter(8),
                    ],
                    validator: _validatePlate,
                    decoration: const InputDecoration(
                      labelText: 'Placa',
                      hintText: 'ABC1D23',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<FuelType?>(
                    initialValue: _fuelType,
                    decoration: const InputDecoration(labelText: 'Combustível'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Não informado'),
                      ),
                      for (final fuel in FuelType.values)
                        DropdownMenuItem(value: fuel, child: Text(fuel.label)),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _fuelType = value),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isSaving ? null : _pickPurchaseDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data da compra',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _purchaseDate == null
                            ? 'Não informada'
                            : formatDate(_purchaseDate!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _purchasePriceController,
                    enabled: !_isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateMoney,
                    decoration: const InputDecoration(
                      labelText: 'Valor da compra',
                      prefixText: 'R\$ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    enabled: !_isSaving,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: context.colors.critical),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'SALVAR ALTERAÇÕES' : 'SALVAR VEÍCULO'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredText(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  String? _validateOdometer(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null) return 'Informe a quilometragem.';
    if (number < 0) return 'A quilometragem não pode ser negativa.';
    return null;
  }

  String? _validateYear(String? value, int maximum) {
    if (value == null || value.isEmpty) return null;
    final year = int.tryParse(value);
    if (year == null || year < 1886 || year > maximum) {
      return 'Ano inválido.';
    }
    return null;
  }

  String? _validateModelYear(String? value) {
    final basicError = _validateYear(value, 2101);
    if (basicError != null || value == null || value.isEmpty) return basicError;

    final manufactureYear = _optionalInt(_manufactureYearController.text);
    final modelYear = int.parse(value);
    if (manufactureYear != null &&
        (modelYear < manufactureYear || modelYear > manufactureYear + 1)) {
      return 'Revise os anos.';
    }
    return null;
  }

  String? _validatePlate(String? value) {
    final normalized = value?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (normalized == null || normalized.isEmpty) return null;
    if (!RegExp(r'^[A-Za-z]{3}[0-9][A-Za-z0-9][0-9]{2}$')
        .hasMatch(normalized)) {
      return 'Use o formato ABC1D23 ou ABC1234.';
    }
    return null;
  }

  String? _validateMoney(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final amount = _optionalMoney(value);
    if (amount == null || amount < 0) return 'Informe um valor válido.';
    return null;
  }

  int? _optionalInt(String value) {
    return value.trim().isEmpty ? null : int.tryParse(value.trim());
  }

  double? _optionalMoney(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }
}

class _CatalogSelectionField extends StatelessWidget {
  const _CatalogSelectionField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
    this.helperText,
  });

  final GlobalKey<FormFieldState<String>> fieldKey;
  final String label;
  final String value;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: fieldKey,
      initialValue: value,
      validator: (selected) => selected == null || selected.trim().isEmpty
          ? 'Informe ${label.toLowerCase()}.'
          : null,
      builder: (field) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            helperText: helperText,
            errorText: field.errorText,
            enabled: enabled || isLoading,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? 'Toque para escolher' : value,
                  style: value.isEmpty
                      ? Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: Theme.of(context).hintColor)
                      : null,
                ),
              ),
              if (isLoading)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.expand_more_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({
    required this.message,
    required this.onRetry,
    required this.onManual,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: context.colors.warning),
          ),
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: onRetry,
                child: const Text('TENTAR NOVAMENTE'),
              ),
              TextButton(
                onPressed: onManual,
                child: const Text('PREENCHER MANUALMENTE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
