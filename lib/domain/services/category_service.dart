import '../../data/repositories/category_repository.dart';
import '../models/category.dart';

class CategoryValidationException implements Exception {
  const CategoryValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CategoryNameConflict implements Exception {
  const CategoryNameConflict(this.existing);
  final Category existing;
}

class CategoryService {
  CategoryService(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final CategoryRepository _repository;
  final DateTime Function() _clock;

  Stream<List<Category>> watchAll() => _repository.watchAll();

  Stream<List<Category>> watchSelectablePrimaryCategories() => watchAll().map(
    (categories) => categories
        .where((category) => category.isPrimary && category.isActive)
        .toList(),
  );

  Stream<List<Category>> watchSelectableSecondaryCategories(int primaryId) =>
      watchAll().map((categories) {
        final primary = categories
            .where((item) => item.id == primaryId)
            .firstOrNull;
        if (primary == null || !primary.isPrimary || !primary.isActive) {
          return const <Category>[];
        }
        return categories
            .where(
              (item) =>
                  item.parentId == primaryId &&
                  item.isActive &&
                  primary.isActive,
            )
            .toList();
      });

  Future<Category> addPrimary(String rawName) async {
    final name = _validateName(rawName);
    await _ensureNameAvailable(name);
    return _repository.create(
      name: name,
      parentId: null,
      sortOrder: await _repository.nextSortOrder(null),
      now: _clock(),
    );
  }

  Future<Category> addSecondary(int parentId, String rawName) async {
    final parent = await _requireActivePrimary(parentId);
    final name = _validateName(rawName);
    await _ensureNameAvailable(name);
    return _repository.create(
      name: name,
      parentId: parent.id,
      sortOrder: await _repository.nextSortOrder(parent.id),
      now: _clock(),
    );
  }

  Future<void> rename(int id, String rawName) async {
    final category = await _requireCategory(id);
    final name = _validateName(rawName);
    if (category.name == name) return;
    await _ensureNameAvailable(name, excludingId: id);
    await _repository.rename(id, name, _clock());
  }

  Future<void> setActive(int id, bool isActive) async {
    await _requireCategory(id);
    await _repository.setActive(id, isActive, _clock());
  }

  Future<void> moveSecondary(int secondaryId, int newParentId) async {
    final secondary = await _requireCategory(secondaryId);
    if (secondary.isPrimary) {
      throw const CategoryValidationException('一级分类不能移动到其他分类下');
    }
    await _requireActivePrimary(newParentId);
    if (secondary.parentId == newParentId) return;
    await _repository.moveSecondary(secondaryId, newParentId, _clock());
  }

  Future<Category> _requireCategory(int id) async {
    final category = await _repository.findById(id);
    if (category == null) throw const CategoryValidationException('分类不存在');
    return category;
  }

  Future<Category> _requireActivePrimary(int id) async {
    final category = await _requireCategory(id);
    if (!category.isPrimary || !category.isActive) {
      throw const CategoryValidationException('请选择启用中的一级分类');
    }
    return category;
  }

  Future<void> _ensureNameAvailable(String name, {int? excludingId}) async {
    final existing = await _repository.findByName(name);
    if (existing != null && existing.id != excludingId) {
      throw CategoryNameConflict(existing);
    }
  }

  String _validateName(String rawName) {
    final name = rawName.trim();
    if (name.isEmpty) throw const CategoryValidationException('分类名称不能为空');
    return name;
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
