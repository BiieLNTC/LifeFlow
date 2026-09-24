import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/finance/data/supabase_category_repository.dart';
import 'package:lifeflow_app/features/finance/domain/category.dart';
import 'package:lifeflow_app/features/finance/domain/category_repository.dart';
import 'package:lifeflow_app/features/finance/presentation/categories_controller.dart';

void main() {
  test('cria, edita e remove categoria', () async {
    final container = ProviderContainer(
      overrides: [categoryRepositoryProvider.overrideWithValue(_Fake())],
    );
    addTearDown(container.dispose);
    await container.read(categoriesControllerProvider.future);
    final controller = container.read(categoriesControllerProvider.notifier);

    final created = await controller.create(_draft('Mercado'));
    expect(created.description, 'Mercado');
    expect(
      container.read(categoriesControllerProvider).value?.single.description,
      'Mercado',
    );

    await controller.updateCategory(created.id, _draft('Supermercado'));
    expect(
      container.read(categoriesControllerProvider).value?.single.description,
      'Supermercado',
    );

    await controller.delete(created.id);
    expect(container.read(categoriesControllerProvider).value, isEmpty);
  });
}

CategoryDraft _draft(String description) => CategoryDraft(
  description: description,
  purpose: CategoryPurpose.expense,
);

class _Fake implements CategoryRepository {
  Category? value;

  @override
  Future<List<Category>> getCategories() async =>
      value == null ? [] : [value!];

  @override
  Future<Category> getCategory(String id) async => value!;

  @override
  Future<Category> saveCategory(String id, CategoryDraft draft) async =>
      value = Category(
        id: id,
        description: draft.description,
        purpose: draft.purpose,
        color: draft.color,
        createdAt: DateTime.utc(2026, 9, 20),
        updatedAt: DateTime.utc(2026, 9, 20),
      );

  @override
  Future<void> deleteCategory(String id) async => value = null;
}
