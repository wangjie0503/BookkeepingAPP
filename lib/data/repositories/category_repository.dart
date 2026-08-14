import 'dart:async';

import 'package:drift/drift.dart';

import '../../domain/models/category.dart';
import '../database/app_database.dart' as database;

class CategoryRepository {
  CategoryRepository(this._database);

  final database.AppDatabase _database;

  Stream<List<Category>> watchAll() =>
      _database.select(_database.categories).watch().map(_mapAndSort);

  Future<List<Category>> getAll() async =>
      _mapAndSort(await _database.select(_database.categories).get());

  Future<Category?> findByName(String name) async {
    final row = await (_database.select(
      _database.categories,
    )..where((table) => table.name.equals(name))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<Category?> findById(int id) async {
    final row = await (_database.select(
      _database.categories,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<int> nextSortOrder(int? parentId) async {
    final query = _database.select(_database.categories)
      ..where(
        (table) => parentId == null
            ? table.parentId.isNull()
            : table.parentId.equals(parentId),
      );
    final rows = await query.get();
    if (rows.isEmpty) return 0;
    return rows.map((row) => row.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<Category> create({
    required String name,
    required int? parentId,
    required int sortOrder,
    required DateTime now,
  }) async {
    final id = await _database
        .into(_database.categories)
        .insert(
          database.CategoriesCompanion.insert(
            name: name,
            parentId: Value(parentId),
            sortOrder: sortOrder,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (await findById(id))!;
  }

  Future<void> rename(int id, String name, DateTime now) =>
      (_database.update(
        _database.categories,
      )..where((table) => table.id.equals(id))).write(
        database.CategoriesCompanion(name: Value(name), updatedAt: Value(now)),
      );

  Future<void> setActive(int id, bool isActive, DateTime now) =>
      (_database.update(
        _database.categories,
      )..where((table) => table.id.equals(id))).write(
        database.CategoriesCompanion(
          isActive: Value(isActive),
          updatedAt: Value(now),
        ),
      );

  Future<void> moveSecondary(int id, int newParentId, DateTime now) =>
      (_database.update(
        _database.categories,
      )..where((table) => table.id.equals(id))).write(
        database.CategoriesCompanion(
          parentId: Value(newParentId),
          updatedAt: Value(now),
        ),
      );

  List<Category> _mapAndSort(List<database.CategoryRow> rows) {
    final result = rows.map(_toModel).toList();
    result.sort((left, right) {
      if (left.parentId == right.parentId) {
        return left.sortOrder.compareTo(right.sortOrder);
      }
      if (left.parentId == null) return -1;
      if (right.parentId == null) return 1;
      final parentCompare = left.parentId!.compareTo(right.parentId!);
      return parentCompare != 0
          ? parentCompare
          : left.sortOrder.compareTo(right.sortOrder);
    });
    return result;
  }

  Category _toModel(database.CategoryRow row) => Category(
    id: row.id,
    name: row.name,
    parentId: row.parentId,
    isActive: row.isActive,
    sortOrder: row.sortOrder,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
