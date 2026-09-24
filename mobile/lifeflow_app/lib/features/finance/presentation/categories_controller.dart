import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/finance/data/supabase_category_repository.dart';
import 'package:lifeflow_app/features/finance/domain/category.dart';
import 'package:uuid/uuid.dart';

final categoriesControllerProvider =
    AsyncNotifierProvider<CategoriesController, List<Category>>(
      CategoriesController.new,
    );

final categoryDetailsProvider = FutureProvider.family<Category, String>(
  (ref, id) => ref.watch(categoryRepositoryProvider).getCategory(id),
);

class CategoriesController extends AsyncNotifier<List<Category>> {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Category>> build() =>
      ref.watch(categoryRepositoryProvider).getCategories();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(categoryRepositoryProvider).getCategories(),
    );
  }

  Future<Category> create(CategoryDraft draft) async {
    final category = await ref
        .read(categoryRepositoryProvider)
        .saveCategory(_uuid.v7(), draft);
    state = AsyncData([category, ...?state.value]);
    return category;
  }

  Future<Category> updateCategory(String id, CategoryDraft draft) async {
    final category = await ref
        .read(categoryRepositoryProvider)
        .saveCategory(id, draft);
    state = AsyncData([
      for (final item in state.value ?? const <Category>[])
        if (item.id == id) category else item,
    ]);
    ref.invalidate(categoryDetailsProvider(id));
    return category;
  }

  Future<void> delete(String id) async {
    await ref.read(categoryRepositoryProvider).deleteCategory(id);
    state = AsyncData(
      (state.value ?? const <Category>[]).where((c) => c.id != id).toList(),
    );
    ref.invalidate(categoryDetailsProvider(id));
  }
}
