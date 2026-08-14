import 'package:drift/drift.dart';

import '../../domain/models/budget_period.dart';
import '../database/app_database.dart' as database;

class PeriodRepository {
  PeriodRepository(this._database);

  final database.AppDatabase _database;

  Future<BudgetPeriod?> findByLabel(int year, int month) async {
    final row =
        await (_database.select(_database.budgetPeriods)..where(
              (table) =>
                  table.labelYear.equals(year) & table.labelMonth.equals(month),
            ))
            .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  /// Looks up a persisted period by its immutable stored date range.
  Future<BudgetPeriod?> findContaining(DateTime date) async {
    final row =
        await (_database.select(_database.budgetPeriods)..where(
              (table) =>
                  table.startAt.isSmallerOrEqualValue(date) &
                  table.endAt.isBiggerOrEqualValue(date),
            ))
            .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<List<BudgetPeriod>> getAll() async {
    final rows = await (_database.select(
      _database.budgetPeriods,
    )..orderBy([(table) => OrderingTerm.asc(table.startAt)])).get();
    return rows.map(_toModel).toList();
  }

  /// Creates once without overwriting an existing period's budget snapshot.
  /// The unique `(label_year, label_month)` constraint resolves concurrent
  /// attempts; both callers then read back the same persisted period.
  Future<BudgetPeriod> createOrGet({
    required int labelYear,
    required int labelMonth,
    required DateTime startAt,
    required DateTime endAt,
    required int budgetJiao,
    required DateTime now,
  }) async {
    await _database
        .into(_database.budgetPeriods)
        .insert(
          database.BudgetPeriodsCompanion.insert(
            labelYear: labelYear,
            labelMonth: labelMonth,
            startAt: startAt,
            endAt: endAt,
            budgetJiao: budgetJiao,
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final period = await findByLabel(labelYear, labelMonth);
    if (period == null) {
      throw StateError('创建生活费周期后无法读取该周期');
    }
    return period;
  }

  Future<void> updateBudget(int id, int budgetJiao, DateTime now) =>
      (_database.update(
        _database.budgetPeriods,
      )..where((table) => table.id.equals(id))).write(
        database.BudgetPeriodsCompanion(
          budgetJiao: Value(budgetJiao),
          updatedAt: Value(now),
        ),
      );

  BudgetPeriod _toModel(database.BudgetPeriodRow row) => BudgetPeriod(
    id: row.id,
    labelYear: row.labelYear,
    labelMonth: row.labelMonth,
    startAt: row.startAt,
    endAt: row.endAt,
    budgetJiao: row.budgetJiao,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
