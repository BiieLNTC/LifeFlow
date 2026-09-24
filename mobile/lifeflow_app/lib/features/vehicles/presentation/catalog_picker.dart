import 'package:flutter/material.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';
import 'package:lifeflow_app/features/vehicles/domain/vehicle_catalog.dart';

Future<VehicleCatalogOption?> showCatalogPicker({
  required BuildContext context,
  required String title,
  required List<VehicleCatalogOption> options,
}) {
  return showModalBottomSheet<VehicleCatalogOption>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.surface,
    builder: (context) => _CatalogPicker(title: title, options: options),
  );
}

class _CatalogPicker extends StatefulWidget {
  const _CatalogPicker({required this.title, required this.options});

  final String title;
  final List<VehicleCatalogOption> options;

  @override
  State<_CatalogPicker> createState() => _CatalogPickerState();
}

class _CatalogPickerState extends State<_CatalogPicker> {
  final _searchController = TextEditingController();
  late List<VehicleCatalogOption> _filteredOptions = widget.options;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _filteredOptions = normalized.isEmpty
          ? widget.options
          : widget.options
                .where(
                  (option) => option.name.toLowerCase().contains(normalized),
                )
                .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                SearchBar(
                  controller: _searchController,
                  autoFocus: true,
                  hintText: 'Pesquisar',
                  leading: const Icon(Icons.search_rounded),
                  onChanged: _filter,
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Limpar pesquisa',
                        onPressed: () {
                          _searchController.clear();
                          _filter('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredOptions.isEmpty
                ? const Center(child: Text('Nenhum resultado encontrado.'))
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: _filteredOptions.length,
                    itemBuilder: (context, index) {
                      final option = _filteredOptions[index];
                      return ListTile(
                        title: Text(option.name),
                        onTap: () => Navigator.pop(context, option),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
