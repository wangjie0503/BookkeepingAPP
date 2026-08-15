import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/period_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/models/app_settings.dart';
import '../domain/models/category.dart';
import '../domain/models/budget_period.dart';
import '../domain/models/expense_list_item.dart';
import '../domain/models/statistics_snapshot.dart';
import '../domain/services/category_service.dart';
import '../domain/services/csv_export_service.dart';
import '../domain/services/expense_service.dart';
import '../domain/services/period_service.dart';
import '../domain/services/settings_service.dart';
import '../domain/services/statistics_service.dart';
import '../shared/date_range.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(databaseProvider)),
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);
final periodRepositoryProvider = Provider<PeriodRepository>(
  (ref) => PeriodRepository(ref.watch(databaseProvider)),
);
final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(databaseProvider)),
);
final categoryServiceProvider = Provider<CategoryService>(
  (ref) => CategoryService(ref.watch(categoryRepositoryProvider)),
);
final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService(ref.watch(settingsRepositoryProvider)),
);
final periodServiceProvider = Provider<PeriodService>(
  (ref) => PeriodService(
    ref.watch(periodRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
  ),
);
final expenseServiceProvider = Provider<ExpenseService>(
  (ref) => ExpenseService(
    ref.watch(expenseRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
    ref.watch(periodServiceProvider),
  ),
);
final statisticsServiceProvider = Provider<StatisticsService>(
  (ref) => StatisticsService(ref.watch(expenseRepositoryProvider)),
);
final csvExportServiceProvider = Provider<CsvExportService>(
  (ref) => CsvExportService(ref.watch(expenseRepositoryProvider)),
);

final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryServiceProvider).watchAll(),
);
final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsServiceProvider).watch(),
);
final periodsProvider = StreamProvider<List<BudgetPeriod>>(
  (ref) => ref.watch(periodRepositoryProvider).watchAll(),
);
final expensesInRangeProvider = StreamProvider.autoDispose
    .family<List<ExpenseListItem>, DateRange>(
      (ref, range) => ref.watch(expenseRepositoryProvider).watchInRange(range),
    );
final statisticsProvider = StreamProvider.autoDispose
    .family<StatisticsSnapshot, StatisticsRequest>(
      (ref, request) => ref
          .watch(statisticsServiceProvider)
          .watchForRange(request.range, budgetJiao: request.budgetJiao),
    );

class StatisticsRequest {
  const StatisticsRequest(this.range, {this.budgetJiao});
  final DateRange range;
  final int? budgetJiao;
  @override
  bool operator ==(Object other) =>
      other is StatisticsRequest &&
      other.range == range &&
      other.budgetJiao == budgetJiao;
  @override
  int get hashCode => Object.hash(range, budgetJiao);
}
