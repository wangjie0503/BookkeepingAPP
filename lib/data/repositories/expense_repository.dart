import 'package:drift/drift.dart';

import '../../domain/models/expense.dart';
import '../../domain/models/expense_list_item.dart';
import '../../shared/date_range.dart';
import '../database/app_database.dart' as database;

class ExpenseRepository {
  ExpenseRepository(this._database);

  final database.AppDatabase _database;

  Stream<List<ExpenseListItem>> watchInRange(DateRange range) {
    final expenses = _database.expenses;
    final secondary = _database.categories.createAlias('secondary_category');
    final primary = _database.categories.createAlias('primary_category');
    final query =
        _database.select(expenses).join([
            innerJoin(
              secondary,
              secondary.id.equalsExp(expenses.secondaryCategoryId),
            ),
            innerJoin(primary, primary.id.equalsExp(secondary.parentId)),
          ])
          ..where(
            expenses.spentAt.isBiggerOrEqualValue(range.start) &
                expenses.spentAt.isSmallerOrEqualValue(range.end),
          )
          ..orderBy([OrderingTerm.desc(expenses.spentAt)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => ExpenseListItem(
              expense: _toExpense(row.readTable(expenses)),
              primaryCategoryId: row.readTable(primary).id,
              primaryCategoryName: row.readTable(primary).name,
              secondaryCategoryName: row.readTable(secondary).name,
            ),
          )
          .toList(),
    );
  }

  Future<List<ExpenseListItem>> getInRange(DateRange range) async {
    final expenses = _database.expenses;
    final secondary = _database.categories.createAlias('secondary_category');
    final primary = _database.categories.createAlias('primary_category');
    final rows =
        await (_database.select(expenses).join([
                innerJoin(
                  secondary,
                  secondary.id.equalsExp(expenses.secondaryCategoryId),
                ),
                innerJoin(primary, primary.id.equalsExp(secondary.parentId)),
              ])
              ..where(
                expenses.spentAt.isBiggerOrEqualValue(range.start) &
                    expenses.spentAt.isSmallerOrEqualValue(range.end),
              )
              ..orderBy([OrderingTerm.desc(expenses.spentAt)]))
            .get();
    return rows
        .map(
          (row) => ExpenseListItem(
            expense: _toExpense(row.readTable(expenses)),
            primaryCategoryId: row.readTable(primary).id,
            primaryCategoryName: row.readTable(primary).name,
            secondaryCategoryName: row.readTable(secondary).name,
          ),
        )
        .toList();
  }

  Future<Expense?> findById(int id) async {
    final row = await (_database.select(
      _database.expenses,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toExpense(row);
  }

  Future<int> create({
    required int amountJiao,
    required int secondaryCategoryId,
    required DateTime spentAt,
    required DateTime now,
  }) => _database
      .into(_database.expenses)
      .insert(
        database.ExpensesCompanion.insert(
          amountJiao: amountJiao,
          secondaryCategoryId: secondaryCategoryId,
          spentAt: spentAt,
          createdAt: now,
          updatedAt: now,
        ),
      );

  Future<void> update({
    required int id,
    required int amountJiao,
    required int secondaryCategoryId,
    required DateTime spentAt,
    required DateTime now,
  }) =>
      (_database.update(
        _database.expenses,
      )..where((table) => table.id.equals(id))).write(
        database.ExpensesCompanion(
          amountJiao: Value(amountJiao),
          secondaryCategoryId: Value(secondaryCategoryId),
          spentAt: Value(spentAt),
          updatedAt: Value(now),
        ),
      );

  Future<void> delete(int id) => (_database.delete(
    _database.expenses,
  )..where((table) => table.id.equals(id))).go();

  Expense _toExpense(database.ExpenseRow row) => Expense(
    id: row.id,
    amountJiao: row.amountJiao,
    secondaryCategoryId: row.secondaryCategoryId,
    spentAt: row.spentAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
