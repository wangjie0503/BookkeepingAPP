import 'package:drift/drift.dart';

import '../../domain/models/app_settings.dart';
import '../database/app_database.dart' as database;

class SettingsRepository {
  SettingsRepository(this._database);

  final database.AppDatabase _database;

  Future<AppSettings> get() async {
    final row = await (_database.select(
      _database.appSettingsTable,
    )..where((table) => table.id.equals(1))).getSingle();
    return AppSettings(
      defaultBudgetJiao: row.defaultBudgetJiao,
      fundingDay: row.fundingDay,
    );
  }

  Stream<AppSettings> watch() => _database
      .select(_database.appSettingsTable)
      .watchSingle()
      .map(
        (row) => AppSettings(
          defaultBudgetJiao: row.defaultBudgetJiao,
          fundingDay: row.fundingDay,
        ),
      );

  Future<void> updateDefaultBudget(int amountJiao) =>
      (_database.update(
        _database.appSettingsTable,
      )..where((table) => table.id.equals(1))).write(
        database.AppSettingsTableCompanion(
          defaultBudgetJiao: Value(amountJiao),
        ),
      );

  Future<void> updateFundingDay(int fundingDay) =>
      (_database.update(
        _database.appSettingsTable,
      )..where((table) => table.id.equals(1))).write(
        database.AppSettingsTableCompanion(fundingDay: Value(fundingDay)),
      );

  Future<bool> canChangeFundingDay() async {
    final hasExpenses = await (_database.select(
      _database.expenses,
    )..limit(1)).getSingleOrNull();
    final hasPeriods = await (_database.select(
      _database.budgetPeriods,
    )..limit(1)).getSingleOrNull();
    return hasExpenses == null && hasPeriods == null;
  }
}
