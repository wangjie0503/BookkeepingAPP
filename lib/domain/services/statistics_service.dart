import '../../data/repositories/expense_repository.dart';
import '../../shared/date_range.dart';
import '../models/expense_list_item.dart';
import '../models/statistics_snapshot.dart';

class StatisticsService {
  StatisticsService(this._expenses);

  final ExpenseRepository _expenses;

  Stream<StatisticsSnapshot> watchForRange(
    DateRange range, {
    int? budgetJiao,
  }) => _expenses
      .watchInRange(range)
      .map((items) => calculate(range, items, budgetJiao: budgetJiao));

  Future<StatisticsSnapshot> forRange(
    DateRange range, {
    int? budgetJiao,
  }) async => calculate(
    range,
    await _expenses.getInRange(range),
    budgetJiao: budgetJiao,
  );

  static StatisticsSnapshot calculate(
    DateRange range,
    List<ExpenseListItem> expenses, {
    int? budgetJiao,
  }) {
    final primary = <int, _PrimaryBuilder>{};
    final days = <DateTime, int>{};
    var total = 0;
    for (final item in expenses) {
      final amount = item.expense.amountJiao;
      total += amount;
      primary
          .putIfAbsent(
            item.primaryCategoryId,
            () => _PrimaryBuilder(item.primaryCategoryName),
          )
          .add(
            item.secondaryCategoryName,
            item.expense.secondaryCategoryId,
            amount,
          );
      final day = DateTime(
        item.expense.spentAt.year,
        item.expense.spentAt.month,
        item.expense.spentAt.day,
      );
      days[day] = (days[day] ?? 0) + amount;
    }
    final primaryTotals =
        primary.entries.map((entry) => entry.value.build(entry.key)).toList()
          ..sort((a, b) => b.amountJiao.compareTo(a.amountJiao));
    final dailyTotals =
        days.entries
            .map((entry) => DailyTotal(day: entry.key, amountJiao: entry.value))
            .toList()
          ..sort((a, b) => a.day.compareTo(b.day));
    return StatisticsSnapshot(
      range: range,
      totalJiao: total,
      budgetJiao: budgetJiao,
      primaryTotals: primaryTotals,
      dailyTotals: dailyTotals,
    );
  }
}

class _PrimaryBuilder {
  _PrimaryBuilder(this.name);
  final String name;
  final Map<int, _SecondaryBuilder> secondaries = {};

  void add(String name, int id, int amount) =>
      secondaries.putIfAbsent(id, () => _SecondaryBuilder(name)).amount +=
          amount;

  PrimaryCategoryTotal build(int id) {
    final totals =
        secondaries.entries
            .map(
              (entry) => CategoryTotal(
                categoryId: entry.key,
                name: entry.value.name,
                amountJiao: entry.value.amount,
              ),
            )
            .toList()
          ..sort((a, b) => b.amountJiao.compareTo(a.amountJiao));
    return PrimaryCategoryTotal(
      categoryId: id,
      name: name,
      amountJiao: totals.fold(0, (sum, item) => sum + item.amountJiao),
      secondaryTotals: totals,
    );
  }
}

class _SecondaryBuilder {
  _SecondaryBuilder(this.name);
  final String name;
  int amount = 0;
}
