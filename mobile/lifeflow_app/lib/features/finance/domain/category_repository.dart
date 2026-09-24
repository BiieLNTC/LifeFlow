import 'package:lifeflow_app/features/finance/domain/category.dart';

class CategoryFailure implements Exception {
  const CategoryFailure(this.message);
  final String message;
}

abstract interface class CategoryRepository {
  Future<List<Category>> getCategories();
  Future<Category> getCategory(String id);
  Future<Category> saveCategory(String id, CategoryDraft draft);
  Future<void> deleteCategory(String id);
}
